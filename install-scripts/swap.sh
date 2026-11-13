#!/usr/bin/env bash

set -euo pipefail
export LC_ALL=C

SWAP_SIZE_SPEC="100GB"
SWAP_SIZE_BYTES=""
SWAP_FILE="/swapfile"
IGNORE_PARTITION=0
SKIP_SWAP_CONFIG=0
PERSIST_ZSWAP=0
APPLY_ZSWAP_NOW=0
ZSWAP_POOL_PERCENT="20"
ZSWAP_COMPRESSOR="zstd"
ZSWAP_OPTION_USED=0
ASSUME_YES=0
DRY_RUN=0

ACTIVE_FILE_SWAPS=()
NON_FILE_SWAPS=()
BLOCK_SWAP_DEVICES=()
BLOCK_SWAP_SIZES=()
BLOCK_SWAP_TOTAL_BYTES=0
CLEANUP_PATHS=()
TEMP_FILES=()
DRY_RUN_TMP_DIR=""

FSTAB_PROPOSED_TMP=""
FSTAB_CHANGED=0
FSTAB_BACKUP=""
GRUB_PROPOSED_TMP=""
GRUB_CHANGED=0
GRUB_BACKUP=""
INITRAMFS_PROPOSED_TMP=""
INITRAMFS_CHANGED=0
INITRAMFS_BACKUP=""
INITRAMFS_MODULE=""
INITRAMFS_MODULES=()

SWAP_FS_TYPE=""
SWAP_CLEANABLE_BYTES=0
SWAPFILE_ACTION="full"
SWAPFILE_SIZE_BYTES=0

OLD_RENAME_ORIGS=()
OLD_RENAME_TMPS=()
NEW_TEMP_PATH=""
NEW_TARGET_CREATED=0
NEW_SWAP_ACTIVE=0
SWAP_ROLLBACK_NEEDED=0

show_help() {
    cat <<'EOF'
Usage: swap.sh [OPTIONS]

Configure a persistent swap file on Ubuntu 24.04. The script must be run as
root; it never invokes sudo and does not install missing packages.

Options:
  --swap-size SIZE          Requested total swap size (default: 100GB).
                            Accepts B, K/M/G/T, KB/MB/GB/TB, and
                            KiB/MiB/GiB/TiB. All units use 1024-based sizes,
                            so 100GB means 100 GiB.
  --swap-file PATH          Absolute swap file path (default: /swapfile).
  --swap-ignore-partition   Deprecated compatibility option; disk-backed
                            swap handling is now automatic.
  --zswap                   Persist zswap kernel arguments in
                            /etc/default/grub and run update-grub and
                            update-initramfs. Takes effect after reboot.
  --zswap-now               Change the running kernel's zswap sysfs settings
                            immediately. This does not make zswap persistent.
  --zswap-pool-percent N    zswap max pool percentage, from 1 to 100
                            (default: 20).
  --zswap-compressor NAME   zswap compressor (default: zstd). It must be
                            available in /proc/crypto.
  --dry-run                 Run all preflight checks and print proposed
                            fstab/GRUB diffs without changing anything.
  -y                        Apply without per-file confirmation. Required in
                            a non-interactive environment.
  -h, --help                Show this help.

Safety notes:
  * Existing active file-backed swap files and file swap entries in
    /etc/fstab are moved aside and replaced. Existing target files are also
    replaced.
  * Existing disk-backed swap is compared with --swap-size. If it is large
    enough, all swap files are removed and the disk-backed swap is retained.
    If it is too small, the script asks whether to exit, create a full-size
    swap file, or create only the missing difference. The default and -y
    policy is to exit without changing swap files. Requested zswap changes
    still proceed. zram and zram configuration are always rejected.
  * Configuration files are backed up before atomic replacement.
  * A module-backed zswap compressor is added to
    /etc/initramfs-tools/modules and verified in every initramfs image.
  * The new swap file must fit within half of the target filesystem's free
    space after reclaiming the old swap files on that filesystem.

--zswap requires a reboot. --zswap-now changes only the running kernel.
EOF
}

log() {
    printf '[swap] %s\n' "$*" >&2
}

warn() {
    printf '[swap] WARNING: %s\n' "$*" >&2
}

die() {
    printf '[swap] ERROR: %s\n' "$*" >&2
    exit 1
}

cleanup_temp_files() {
    local path
    for path in "${TEMP_FILES[@]}"; do
        if [[ -n "$path" && -e "$path" ]]; then
            rm -f -- "$path"
        fi
    done
    if [[ -n "$DRY_RUN_TMP_DIR" && -d "$DRY_RUN_TMP_DIR" ]]; then
        rmdir -- "$DRY_RUN_TMP_DIR" 2>/dev/null || true
    fi
}

on_exit() {
    local status=$?
    if ((status != 0 && SWAP_ROLLBACK_NEEDED == 1)); then
        rollback_swap_stage || true
    fi
    cleanup_temp_files
}

array_contains() {
    local needle="$1"
    shift
    local item
    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done
    return 1
}

add_unique_path() {
    local path="$1"
    if ! array_contains "$path" "${CLEANUP_PATHS[@]}"; then
        CLEANUP_PATHS+=("$path")
    fi
}

add_non_file_swap() {
    local device="$1"
    if ! array_contains "$device" "${NON_FILE_SWAPS[@]}"; then
        NON_FILE_SWAPS+=("$device")
    fi
}

add_block_swap_device() {
    local device="$1"
    local size="$2"
    local index

    if [[ -e "$device" ]]; then
        device="$(realpath -e -- "$device")"
    fi
    if [[ ! "$size" =~ ^[0-9]+$ ]]; then
        die "could not determine swap size for block device: $device"
    fi
    add_non_file_swap "$device"
    for ((index = 0; index < ${#BLOCK_SWAP_DEVICES[@]}; index++)); do
        if [[ "${BLOCK_SWAP_DEVICES[index]}" == "$device" ]]; then
            return 0
        fi
    done
    BLOCK_SWAP_DEVICES+=("$device")
    BLOCK_SWAP_SIZES+=("$size")
}

check_argument_available() {
    local option="$1"
    local remaining="$2"
    if ((remaining < 2)); then
        die "$option requires a value"
    fi
}

parse_arguments() {
    while (($# > 0)); do
        case "$1" in
            --swap-size)
                check_argument_available "$1" "$#"
                SWAP_SIZE_SPEC="$2"
                shift 2
                ;;
            --swap-file)
                check_argument_available "$1" "$#"
                SWAP_FILE="$2"
                shift 2
                ;;
            --swap-ignore-partition)
                IGNORE_PARTITION=1
                shift
                ;;
            --zswap)
                PERSIST_ZSWAP=1
                shift
                ;;
            --zswap-now)
                APPLY_ZSWAP_NOW=1
                shift
                ;;
            --zswap-pool-percent)
                check_argument_available "$1" "$#"
                ZSWAP_POOL_PERCENT="$2"
                ZSWAP_OPTION_USED=1
                shift 2
                ;;
            --zswap-compressor)
                check_argument_available "$1" "$#"
                ZSWAP_COMPRESSOR="$2"
                ZSWAP_OPTION_USED=1
                shift 2
                ;;
            --dry-run)
                DRY_RUN=1
                shift
                ;;
            -y)
                ASSUME_YES=1
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                die "unknown option: $1 (use --help for usage)"
                ;;
        esac
    done
}

decimal_string_greater() {
    local left="$1"
    local right="$2"
    local left_digit right_digit index

    ((${#left} == ${#right})) || return 1
    for ((index = 0; index < ${#left}; index++)); do
        left_digit="${left:index:1}"
        right_digit="${right:index:1}"
        if ((10#$left_digit > 10#$right_digit)); then
            return 0
        fi
        if ((10#$left_digit < 10#$right_digit)); then
            return 1
        fi
    done
    return 1
}

parse_swap_size() {
    local spec="$1"
    local digits unit multiplier max_number

    if [[ ! "$spec" =~ ^([0-9]+)(.+)$ ]]; then
        die "invalid swap size '$spec'; use an integer followed by B, K/M/G/T, KB/MB/GB/TB, or KiB/MiB/GiB/TiB"
    fi

    digits="${BASH_REMATCH[1]}"
    unit="${BASH_REMATCH[2]^^}"
    while [[ "$digits" == 0* && ${#digits} -gt 1 ]]; do
        digits="${digits#0}"
    done
    if [[ "$digits" == "0" ]]; then
        die "swap size must be greater than zero"
    fi

    case "$unit" in
        B)
            multiplier=1
            max_number="9223372036854775807"
            ;;
        K|KB|KIB)
            multiplier=1024
            max_number="9007199254740991"
            ;;
        M|MB|MIB)
            multiplier=$((1024 * 1024))
            max_number="8796093022207"
            ;;
        G|GB|GIB)
            multiplier=$((1024 * 1024 * 1024))
            max_number="8589934591"
            ;;
        T|TB|TIB)
            multiplier=$((1024 * 1024 * 1024 * 1024))
            max_number="8388607"
            ;;
        *)
            die "unsupported swap size unit '$unit'"
            ;;
    esac

    if ((${#digits} > ${#max_number})); then
        die "swap size '$spec' is too large"
    fi
    if ((${#digits} == ${#max_number})) && decimal_string_greater "$digits" "$max_number"; then
        die "swap size '$spec' is too large"
    fi

    SWAP_SIZE_BYTES=$((10#$digits * multiplier))
}

validate_arguments() {
    parse_swap_size "$SWAP_SIZE_SPEC"

    if [[ ! "$SWAP_FILE" =~ ^/ ]]; then
        die "--swap-file must be an absolute path"
    fi
    if [[ "$SWAP_FILE" =~ [[:space:][:cntrl:]] ]]; then
        die "--swap-file must not contain whitespace or control characters"
    fi
    if [[ "$SWAP_FILE" == "/" ]]; then
        die "--swap-file must name a file, not /"
    fi

    if [[ ! "$ZSWAP_POOL_PERCENT" =~ ^[0-9]+$ ]]; then
        die "--zswap-pool-percent must be an integer from 1 to 100"
    fi
    while [[ "$ZSWAP_POOL_PERCENT" == 0* && ${#ZSWAP_POOL_PERCENT} -gt 1 ]]; do
        ZSWAP_POOL_PERCENT="${ZSWAP_POOL_PERCENT#0}"
    done
    if ((${#ZSWAP_POOL_PERCENT} > 3)); then
        die "--zswap-pool-percent must be between 1 and 100"
    fi
    ZSWAP_POOL_PERCENT=$((10#$ZSWAP_POOL_PERCENT))
    if ((ZSWAP_POOL_PERCENT < 1 || ZSWAP_POOL_PERCENT > 100)); then
        die "--zswap-pool-percent must be between 1 and 100"
    fi

    if [[ ! "$ZSWAP_COMPRESSOR" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]]; then
        die "--zswap-compressor must be a kernel compression algorithm name"
    fi
    if ((ZSWAP_OPTION_USED == 1 && PERSIST_ZSWAP == 0 && APPLY_ZSWAP_NOW == 0)); then
        die "zswap options require --zswap or --zswap-now"
    fi
}

check_root_os_and_interaction() {
    if ((DRY_RUN == 0 && EUID != 0)); then
        die "must be run as root (the script does not invoke sudo)"
    fi

    # shellcheck source=/dev/null
    . /etc/os-release
    if [[ "${ID:-}" != "ubuntu" || "${VERSION_ID:-}" != "24.04" ]]; then
        die "this script supports Ubuntu 24.04 only"
    fi

    if ((DRY_RUN == 1 && EUID != 0)); then
        log "Running an unprivileged dry run with read-only system inspection"
    fi

    if ((DRY_RUN == 0 && ASSUME_YES == 0)); then
        if ! isatty 0; then
            die "interactive confirmation is unavailable; rerun with -y"
        fi
    fi
}

isatty() {
    [[ -t "$1" ]]
}

require_commands() {
    local commands=(
        awk
        basename
        blkid
        chmod
        chown
        cmp
        cp
        date
        df
        diff
        dirname
        fallocate
        findmnt
        flock
        lsblk
        mkdir
        mkswap
        mktemp
        mv
        realpath
        rm
        rmdir
        stat
        swapon
        swapoff
        uname
    )
    local command_name

    if ((PERSIST_ZSWAP == 1)); then
        commands+=(lsinitramfs update-grub update-initramfs)
    fi
    for command_name in "${commands[@]}"; do
        if ! command -v "$command_name" >/dev/null 2>&1; then
            die "required command not found: $command_name"
        fi
    done
}

check_zram() {
    local generator_configs=(
        /etc/systemd/zram-generator.conf
        /etc/systemd/zram-generator.conf.d/*.conf
    )
    local config_file

    shopt -s nullglob
    local zram_devices=(/sys/block/zram*)
    shopt -u nullglob
    if ((${#zram_devices[@]} > 0)); then
        die "zram is present (${zram_devices[*]}); zram and swap files cannot be configured together"
    fi

    for config_file in "${generator_configs[@]}"; do
        if [[ -f "$config_file" ]] &&
            awk '
                /^[[:space:]]*#/ { next }
                /^[[:space:]]*$/ { next }
                /^[[:space:]]*\[zram[0-9]+\][[:space:]]*$/ { found = 1 }
                END { exit !found }
            ' "$config_file"; then
            die "zram-generator configuration detected: $config_file"
        fi
    done

    for config_file in /etc/default/zramswap /etc/zramswap.conf; do
        if [[ -f "$config_file" ]] &&
            awk '
                /^[[:space:]]*#/ { next }
                /^[[:space:]]*$/ { next }
                {
                    line = tolower($0)
                    if (line ~ /^[[:space:]]*enabled[[:space:]]*=[[:space:]]*(false|0|no)[[:space:]]*$/) {
                        disabled = 1
                    }
                    found = 1
                }
                END { exit !(found && !disabled) }
            ' "$config_file"; then
            die "zramswap configuration detected: $config_file"
        fi
    done
}

decode_fstab_path() {
    local value="$1"
    value="${value//\\040/ }"
    value="${value//\\011/$'\t'}"
    value="${value//\\012/$'\n'}"
    value="${value//\\134/\\}"
    printf '%s' "$value"
}

decode_swapon_name() {
    printf '%b' "$1"
}

canonicalize_path() {
    realpath -m -- "$1"
}

validate_target_path() {
    local parent

    if [[ -L "$SWAP_FILE" ]]; then
        die "swap file path must not be a symbolic link: $SWAP_FILE"
    fi
    SWAP_FILE="$(canonicalize_path "$SWAP_FILE")"
    if [[ -L "$SWAP_FILE" ]]; then
        die "swap file path resolves to a symbolic link: $SWAP_FILE"
    fi

    parent="$(dirname -- "$SWAP_FILE")"
    if [[ ! -d "$parent" ]]; then
        die "swap file directory does not exist: $parent"
    fi
    if ((DRY_RUN == 0)) && [[ ! -w "$parent" ]]; then
        die "swap file directory is not writable: $parent"
    fi
    if [[ -e "$SWAP_FILE" && ! -f "$SWAP_FILE" ]]; then
        die "swap file target exists but is not a regular file: $SWAP_FILE"
    fi
}

collect_active_swaps() {
    local output line name type size decoded_name

    output="$(swapon --show=NAME,TYPE,SIZE,PRIO --bytes --noheadings --raw)" ||
        die "failed to read active swap devices"
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        read -r name type size _ <<<"$line"
        decoded_name="$(decode_swapon_name "$name")"

        if [[ "$decoded_name" == /dev/zram* || "$type" == "zram" ]]; then
            die "active zram swap detected: $decoded_name"
        fi

        if [[ "$type" == "file" ]]; then
            if [[ ! "$decoded_name" =~ ^/ ]]; then
                die "active file swap path is not absolute: $decoded_name"
            fi
            decoded_name="$(canonicalize_path "$decoded_name")"
            if ! array_contains "$decoded_name" "${ACTIVE_FILE_SWAPS[@]}"; then
                ACTIVE_FILE_SWAPS+=("$decoded_name")
            fi
            add_unique_path "$decoded_name"
        else
            add_block_swap_device "$decoded_name" "$size"
        fi
    done <<<"$output"
}

collect_block_swaps() {
    local device path filesystem size lsblk_output

    while IFS= read -r device; do
        [[ -z "$device" ]] && continue
        size="$(lsblk -nrbo SIZE -- "$device" 2>/dev/null | awk 'NR == 1 { print $1 }')"
        add_block_swap_device "$device" "$size"
    done < <(blkid -t TYPE=swap -o device 2>/dev/null || true)

    if ! lsblk_output="$(lsblk -nrbo PATH,FSTYPE,SIZE 2>/dev/null)"; then
        die "cannot inspect block device filesystem signatures with lsblk (run as root if necessary)"
    fi
    while IFS= read -r path filesystem size; do
        [[ -z "$path" ]] && continue
        if [[ "$filesystem" == "swap" ]]; then
            add_block_swap_device "$path" "$size"
        fi
    done <<<"$lsblk_output"
}

collect_fstab_file_swaps() {
    local line source mountpoint filesystem rest decoded_source

    if [[ ! -f /etc/fstab || ! -r /etc/fstab ]]; then
        die "/etc/fstab does not exist or is not readable"
    fi

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        read -r source mountpoint filesystem rest <<<"$line"
        if [[ "${mountpoint:-}" != "none" || "${filesystem:-}" != "swap" ]]; then
            continue
        fi

        decoded_source="$(decode_fstab_path "$source")"
        case "$decoded_source" in
            /dev/*|UUID=*|LABEL=*|PARTUUID=*|PARTLABEL=*)
                add_non_file_swap "$decoded_source"
                ;;
            /*)
                add_unique_path "$(canonicalize_path "$decoded_source")"
                ;;
            *)
                add_non_file_swap "$decoded_source"
                ;;
        esac
    done </etc/fstab
}

validate_cleanup_paths() {
    local path
    for path in "${CLEANUP_PATHS[@]}"; do
        if [[ -L "$path" ]]; then
            die "refusing to manage symbolic-link swap path: $path"
        fi
        if [[ -e "$path" && ! -f "$path" ]]; then
            die "swap cleanup target is not a regular file: $path"
        fi
    done
}

calculate_block_swap_total() {
    local index size

    BLOCK_SWAP_TOTAL_BYTES=0
    for ((index = 0; index < ${#BLOCK_SWAP_SIZES[@]}; index++)); do
        size="${BLOCK_SWAP_SIZES[index]}"
        if ((BLOCK_SWAP_TOTAL_BYTES > 9223372036854775807 - size)); then
            die "total disk-backed swap size overflows the supported range"
        fi
        BLOCK_SWAP_TOTAL_BYTES=$((BLOCK_SWAP_TOTAL_BYTES + size))
    done
}

choose_swapfile_strategy() {
    local answer difference

    if ((BLOCK_SWAP_TOTAL_BYTES >= SWAP_SIZE_BYTES)); then
        SWAPFILE_ACTION="remove"
        SWAPFILE_SIZE_BYTES=0
        log "Disk-backed swap is sufficient (${BLOCK_SWAP_TOTAL_BYTES} bytes); existing swap files will be removed"
        return 0
    fi

    difference=$((SWAP_SIZE_BYTES - BLOCK_SWAP_TOTAL_BYTES))
    log "Disk-backed swap is smaller than requested: ${BLOCK_SWAP_TOTAL_BYTES} bytes available, ${SWAP_SIZE_BYTES} bytes requested"

    if ((ASSUME_YES == 1)) || [[ ! -t 0 ]]; then
        SWAPFILE_ACTION="none"
        SKIP_SWAP_CONFIG=1
        warn "Default policy selected: exit without changing existing swap files"
        return 0
    fi

    printf '%s\n' \
        'Choose the swap-file strategy:' \
        '  1) Exit without changing existing swap files [default]' \
        "  2) Create a full ${SWAP_SIZE_BYTES}-byte swap file" \
        "  3) Create a ${difference}-byte swap file (requested minus existing disk swap)" >&2
    read -r -p "Selection [1]: " answer
    case "$answer" in
        2)
            SWAPFILE_ACTION="full"
            SWAPFILE_SIZE_BYTES="$SWAP_SIZE_BYTES"
            ;;
        3)
            SWAPFILE_ACTION="difference"
            SWAPFILE_SIZE_BYTES="$difference"
            ;;
        *)
            SWAPFILE_ACTION="none"
            SKIP_SWAP_CONFIG=1
            log "Exiting without changing existing swap files"
            return 0
            ;;
    esac
    log "Selected swap-file size: $SWAPFILE_SIZE_BYTES bytes"
}

detect_swap_state() {
    collect_active_swaps
    collect_block_swaps
    collect_fstab_file_swaps
    calculate_block_swap_total

    if ((${#NON_FILE_SWAPS[@]} > 0)); then
        printf '[swap] Disk-backed swap detected:\n' >&2
        printf '  %s\n' "${NON_FILE_SWAPS[@]}" >&2
        if ((IGNORE_PARTITION == 1)); then
            log "--swap-ignore-partition is no longer required"
        fi
        choose_swapfile_strategy
    elif ((BLOCK_SWAP_TOTAL_BYTES > 0)); then
        choose_swapfile_strategy
    else
        SWAPFILE_ACTION="full"
        SWAPFILE_SIZE_BYTES="$SWAP_SIZE_BYTES"
    fi

    if [[ "$SWAPFILE_ACTION" == "none" ]]; then
        return 0
    fi

    if [[ "$SWAPFILE_ACTION" == "remove" ]]; then
        if [[ -L "$SWAP_FILE" ]]; then
            die "swap file path must not be a symbolic link: $SWAP_FILE"
        fi
        SWAP_FILE="$(canonicalize_path "$SWAP_FILE")"
        if [[ -e "$SWAP_FILE" && ! -f "$SWAP_FILE" ]]; then
            die "swap file target exists but is not a regular file: $SWAP_FILE"
        fi
        add_unique_path "$SWAP_FILE"
        validate_cleanup_paths
        return 0
    fi

    validate_target_path
    add_unique_path "$SWAP_FILE"
    validate_cleanup_paths
}

check_swap_capacity() {
    local parent filesystem available target_device candidate candidate_device blocks
    local reclaimable=0 candidate_bytes

    parent="$(dirname -- "$SWAP_FILE")"
    filesystem="$(findmnt -n -o FSTYPE --target "$parent" | awk 'NR == 1 { print $1 }')"
    case "$filesystem" in
        ext2|ext3|ext4|xfs|btrfs)
            SWAP_FS_TYPE="$filesystem"
            ;;
        "")
            die "could not determine the filesystem for $parent"
            ;;
        *)
            die "unsupported swap file filesystem '$filesystem' for $parent"
            ;;
    esac

    if [[ "$SWAP_FS_TYPE" == "btrfs" ]] && ! command -v chattr >/dev/null 2>&1; then
        die "required command not found for btrfs: chattr"
    fi

    available="$(df -P -B1 -- "$parent" | awk 'NR == 2 { print $4 }')"
    if [[ ! "$available" =~ ^[0-9]+$ ]]; then
        die "could not determine available space for $parent"
    fi
    target_device="$(stat -c '%d' -- "$parent")"

    for candidate in "${CLEANUP_PATHS[@]}"; do
        [[ -f "$candidate" ]] || continue
        candidate_device="$(stat -c '%d' -- "$candidate")"
        [[ "$candidate_device" == "$target_device" ]] || continue
        blocks="$(stat -c '%b' -- "$candidate")"
        if [[ ! "$blocks" =~ ^[0-9]+$ ]]; then
            die "could not determine allocated blocks for $candidate"
        fi
        if ((blocks > (9223372036854775807 / 512))); then
            die "allocated size is too large to calculate for $candidate"
        fi
        candidate_bytes=$((blocks * 512))
        if ((reclaimable > 9223372036854775807 - candidate_bytes)); then
            die "reclaimable size overflows while calculating capacity"
        fi
        reclaimable=$((reclaimable + candidate_bytes))
    done

    if ((available > 9223372036854775807 - reclaimable)); then
        SWAP_CLEANABLE_BYTES=9223372036854775807
    else
        SWAP_CLEANABLE_BYTES=$((available + reclaimable))
    fi

    if ((SWAPFILE_SIZE_BYTES > SWAP_CLEANABLE_BYTES / 2)); then
        die "requested swap file size $SWAPFILE_SIZE_BYTES bytes exceeds half of the cleanable free space ($SWAP_CLEANABLE_BYTES bytes) on $filesystem"
    fi

    log "Filesystem: $filesystem; cleanable free space: $SWAP_CLEANABLE_BYTES bytes"
}

compression_algorithm_registered() {
    local compressor="$1"
    [[ -r /proc/crypto ]] &&
        awk -v wanted="$compressor" '
            /^name[[:space:]]*:/ { current = $3 }
            /^type[[:space:]]*:/ {
                if (current == wanted &&
                    ($3 == "acomp" || $3 == "scomp" || $3 == "compression")) {
                    found = 1
                }
            }
            END { exit !found }
        ' /proc/crypto
}

resolve_compression_modules() {
    local compressor="$1"
    local output action path module_name found=0 builtin=0

    INITRAMFS_MODULE=""
    INITRAMFS_MODULES=()
    if ! command -v modprobe >/dev/null 2>&1; then
        return 1
    fi
    if ! output="$(modprobe --dry-run --quiet --show-depends "crypto-$compressor")"; then
        return 1
    fi

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        read -r action path _ <<<"$line"
        case "$action" in
            builtin)
                builtin=1
                ;;
            insmod)
                module_name="${path##*/}"
                module_name="${module_name%%.ko*}"
                if [[ -n "$module_name" ]] &&
                    ! array_contains "$module_name" "${INITRAMFS_MODULES[@]}"; then
                    INITRAMFS_MODULES+=("$module_name")
                fi
                INITRAMFS_MODULE="$module_name"
                found=1
                ;;
        esac
    done <<<"$output"

    ((found == 1 || builtin == 1))
}

compression_algorithm_module_available() {
    local compressor="$1"

    resolve_compression_modules "$compressor"
}

validate_zswap() {
    local parameter_dir="/sys/module/zswap/parameters"
    local registered=0

    if ((PERSIST_ZSWAP == 1 || APPLY_ZSWAP_NOW == 1)); then
        if compression_algorithm_registered "$ZSWAP_COMPRESSOR"; then
            log "Kernel compression algorithm is registered: $ZSWAP_COMPRESSOR"
            registered=1
        fi
        if ((registered == 0)) && ! compression_algorithm_module_available "$ZSWAP_COMPRESSOR"; then
            die "kernel compression algorithm '$ZSWAP_COMPRESSOR' is neither registered in /proc/crypto nor available as module crypto-$ZSWAP_COMPRESSOR"
        fi

        if ((PERSIST_ZSWAP == 1)); then
            if ! resolve_compression_modules "$ZSWAP_COMPRESSOR"; then
                die "cannot resolve the initramfs module for kernel compression algorithm '$ZSWAP_COMPRESSOR'"
            fi
            if ((${#INITRAMFS_MODULES[@]} > 0)); then
                log "Initramfs will include module $INITRAMFS_MODULE for $ZSWAP_COMPRESSOR"
            else
                log "Kernel compression algorithm is built in; no initramfs module is required: $ZSWAP_COMPRESSOR"
            fi
        elif ((registered == 0)); then
            log "Kernel compression module is available and will be loaded when needed: crypto-$ZSWAP_COMPRESSOR"
        fi
    fi

    if ((PERSIST_ZSWAP == 1)); then
        if [[ ! -f /etc/default/grub || ! -r /etc/default/grub ]]; then
            die "/etc/default/grub does not exist or is not readable"
        fi
        if ((${#INITRAMFS_MODULES[@]} > 0)) &&
            [[ ! -f /etc/initramfs-tools/modules || ! -r /etc/initramfs-tools/modules ]]; then
            die "/etc/initramfs-tools/modules does not exist or is not readable"
        fi
    fi

    if ((APPLY_ZSWAP_NOW == 1)); then
        local parameter
        for parameter in compressor max_pool_percent enabled; do
            if [[ ! -f "$parameter_dir/$parameter" || ! -r "$parameter_dir/$parameter" ]]; then
                die "zswap sysfs parameter is missing or not readable: $parameter_dir/$parameter"
            fi
            if ((DRY_RUN == 0)) && [[ ! -w "$parameter_dir/$parameter" ]]; then
                die "zswap sysfs parameter is not writable: $parameter_dir/$parameter"
            fi
        done
    fi
}

prepare_initramfs_proposal() {
    make_config_temp /etc/initramfs-tools/modules INITRAMFS_PROPOSED_TMP

    INITRAMFS_MODULE="$INITRAMFS_MODULE" awk '
        {
            if ($1 !~ /^#/ && $1 == ENVIRON["INITRAMFS_MODULE"]) {
                found = 1
            }
            print
        }
        END {
            if (!found) {
                print ENVIRON["INITRAMFS_MODULE"]
            }
        }
    ' /etc/initramfs-tools/modules >"$INITRAMFS_PROPOSED_TMP"

    if cmp -s -- /etc/initramfs-tools/modules "$INITRAMFS_PROPOSED_TMP"; then
        INITRAMFS_CHANGED=0
    else
        INITRAMFS_CHANGED=1
    fi
}

verify_initramfs_modules() {
    local initrd base version module listing found=0

    shopt -s nullglob
    local initrds=(/boot/initrd.img-*)
    shopt -u nullglob

    for initrd in "${initrds[@]}"; do
        base="$(basename -- "$initrd")"
        [[ "$base" =~ ^initrd\.img-[0-9] ]] || continue
        [[ -f "$initrd" ]] || continue
        version="${base#initrd.img-}"
        if [[ ! -e "/boot/vmlinuz-$version" && ! -d "/lib/modules/$version" ]]; then
            continue
        fi
        found=1
        if ! listing="$(lsinitramfs "$initrd" 2>/dev/null)"; then
            warn "failed to inspect initramfs: $initrd"
            return 1
        fi
        for module in "${INITRAMFS_MODULES[@]}"; do
            if ! awk -v wanted="/$module.ko" 'index($0, wanted) { found = 1 } END { exit !found }' <<<"$listing"; then
                warn "module $module is missing from initramfs: $initrd"
                return 1
            fi
        done
    done

    if ((found == 0)); then
        warn "no versioned initramfs image was found under /boot"
        return 1
    fi
    log "Verified compression modules in all versioned initramfs images"
}

make_config_temp() {
    local original="$1"
    local output_variable="$2"
    local directory base temporary

    base="$(basename -- "$original")"
    if ((DRY_RUN == 1)); then
        if [[ -z "$DRY_RUN_TMP_DIR" ]]; then
            if ! DRY_RUN_TMP_DIR="$(mktemp -d -- "${TMPDIR:-/tmp}/xs-env-swap.XXXXXX")"; then
                die "failed to create a temporary directory for dry-run proposals"
            fi
        fi
        if ! temporary="$(mktemp -- "$DRY_RUN_TMP_DIR/${base}.XXXXXX")"; then
            die "failed to create a temporary config proposal for $original"
        fi
    else
        directory="$(dirname -- "$original")"
        if ! temporary="$(mktemp -- "$directory/.${base}.xs-env.XXXXXX")"; then
            die "failed to create a temporary config file beside $original"
        fi
        chmod --reference="$original" -- "$temporary"
        chown --reference="$original" -- "$temporary"
    fi
    TEMP_FILES+=("$temporary")
    printf -v "$output_variable" '%s' "$temporary"
}

fstab_escape_path() {
    local path="$1"
    local i char escaped=""

    for ((i = 0; i < ${#path}; i++)); do
        char="${path:i:1}"
        case "$char" in
            \\)
                escaped+='\134'
                ;;
            $'\t')
                escaped+='\011'
                ;;
            $'\n')
                escaped+='\012'
                ;;
            ' ')
                escaped+='\040'
                ;;
            *)
                escaped+="$char"
                ;;
        esac
    done
    printf '%s' "$escaped"
}

prepare_fstab_proposal() {
    local escaped_target append_entry=1
    escaped_target="$(fstab_escape_path "$SWAP_FILE")"
    if [[ "$SWAPFILE_ACTION" == "remove" ]]; then
        append_entry=0
    fi
    make_config_temp /etc/fstab FSTAB_PROPOSED_TMP

    FSTAB_TARGET="$escaped_target" FSTAB_APPEND="$append_entry" awk '
        function is_file_swap_source(source) {
            return source ~ /^\// && source !~ /^\/dev(\/|$)/
        }
        {
            if (NF >= 3 && $1 !~ /^#/ && $2 == "none" && $3 == "swap" &&
                is_file_swap_source($1)) {
                next
            }
            print
        }
        END {
            if (ENVIRON["FSTAB_APPEND"] == "1") {
                print ENVIRON["FSTAB_TARGET"] " none swap sw 0 0"
            }
        }
    ' /etc/fstab >"$FSTAB_PROPOSED_TMP"

    if cmp -s -- /etc/fstab "$FSTAB_PROPOSED_TMP"; then
        FSTAB_CHANGED=0
    else
        FSTAB_CHANGED=1
    fi
}

prepare_grub_proposal() {
    make_config_temp /etc/default/grub GRUB_PROPOSED_TMP

    ZSWAP_COMPRESSOR="$ZSWAP_COMPRESSOR" \
        ZSWAP_POOL_PERCENT="$ZSWAP_POOL_PERCENT" \
        awk '
            function trim(value) {
                sub(/^[[:space:]]+/, "", value)
                sub(/[[:space:]]+$/, "", value)
                return value
            }

            function parse_value(input,    quote, i, char, escaped, value, trailing) {
                input = trim(input)
                trailing = ""
                if (input == "") {
                    return ""
                }

                quote = substr(input, 1, 1)
                if (quote == "\047" || quote == "\"") {
                    value = ""
                    escaped = 0
                    for (i = 2; i <= length(input); i++) {
                        char = substr(input, i, 1)
                        if (quote == "\"" && escaped) {
                            value = value char
                            escaped = 0
                        } else if (quote == "\"" && char == "\\") {
                            value = value char
                            escaped = 1
                        } else if (char == quote) {
                            trailing = trim(substr(input, i + 1))
                            return value
                        } else {
                            value = value char
                        }
                    }
                    return value
                }

                value = input
                sub(/[[:space:]]+#.*$/, "", value)
                return trim(value)
            }

            function transformed(value, add_values,    count, tokens, i, output) {
                output = ""
                count = split(trim(value), tokens, /[[:space:]]+/)
                for (i = 1; i <= count; i++) {
                    if (tokens[i] != "" && tokens[i] !~ /^zswap\./) {
                        output = output (output == "" ? "" : " ") tokens[i]
                    }
                }
                if (add_values) {
                    output = output (output == "" ? "" : " ") \
                        "zswap.enabled=1 zswap.compressor=" ENVIRON["ZSWAP_COMPRESSOR"] \
                        " zswap.max_pool_percent=" ENVIRON["ZSWAP_POOL_PERCENT"]
                }
                return output
            }

            BEGIN {
                add_to_default = 1
                saw_default = 0
            }

            /^[[:space:]]*(GRUB_CMDLINE_LINUX_DEFAULT|GRUB_CMDLINE_LINUX)[[:space:]]*=/ {
                match($0, /^[[:space:]]*(GRUB_CMDLINE_LINUX_DEFAULT|GRUB_CMDLINE_LINUX)[[:space:]]*=/)
                assignment = substr($0, RSTART, RLENGTH)
                key = assignment
                sub(/^[[:space:]]*/, "", key)
                sub(/[[:space:]]*=.*$/, "", key)
                indent = substr(assignment, 1, length(assignment) - length(trim(assignment)))
                value = parse_value(substr($0, RLENGTH + 1))

                add_now = 0
                if (key == "GRUB_CMDLINE_LINUX_DEFAULT") {
                    saw_default = 1
                    if (add_to_default) {
                        add_now = 1
                        add_to_default = 0
                    }
                }
                value = transformed(value, add_now)
                print indent key "=\"" value "\""
                next
            }

            {
                print
            }

            END {
                if (add_to_default) {
                    print "GRUB_CMDLINE_LINUX_DEFAULT=\"zswap.enabled=1" \
                        " zswap.compressor=" ENVIRON["ZSWAP_COMPRESSOR"] \
                        " zswap.max_pool_percent=" ENVIRON["ZSWAP_POOL_PERCENT"] "\""
                }
            }
        ' /etc/default/grub >"$GRUB_PROPOSED_TMP"

    if cmp -s -- /etc/default/grub "$GRUB_PROPOSED_TMP"; then
        GRUB_CHANGED=0
    else
        GRUB_CHANGED=1
    fi
}

print_diff() {
    local file="$1"
    local proposed="$2"
    local description="$3"
    local status=0

    printf '\n[swap] Proposed %s changes:\n' "$description" >&2
    diff -u --label "$file (current)" --label "$file (proposed)" "$file" "$proposed" ||
        status=$?
    if ((status > 1)); then
        die "failed to generate diff for $file"
    fi
}

confirm() {
    local prompt="$1"
    local answer

    if ((ASSUME_YES == 1)); then
        return 0
    fi
    if [[ ! -t 0 ]]; then
        die "interactive confirmation is unavailable; rerun with -y"
    fi

    read -r -p "$prompt [y/N] " answer
    case "$answer" in
        y|Y|yes|YES|Yes)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

confirm_plan() {
    local prompted=0

    if ((FSTAB_CHANGED == 1)); then
        print_diff /etc/fstab "$FSTAB_PROPOSED_TMP" "fstab"
        if ! confirm "Apply the fstab change?"; then
            die "aborted; no changes were made"
        fi
        prompted=1
    fi

    if ((PERSIST_ZSWAP == 1 && GRUB_CHANGED == 1)); then
        print_diff /etc/default/grub "$GRUB_PROPOSED_TMP" "GRUB"
        if ! confirm "Apply the GRUB change?"; then
            die "aborted; no changes were made"
        fi
        prompted=1
    fi

    if ((PERSIST_ZSWAP == 1 && INITRAMFS_CHANGED == 1)); then
        print_diff /etc/initramfs-tools/modules "$INITRAMFS_PROPOSED_TMP" "initramfs module list"
        if ! confirm "Add the compression module to the initramfs module list?"; then
            die "aborted; no changes were made"
        fi
        prompted=1
    fi

    if ((prompted == 0)); then
        if [[ "$SWAPFILE_ACTION" == "none" ]]; then
            if ! confirm "Proceed with zswap configuration?"; then
                die "aborted; no changes were made"
            fi
        elif [[ "$SWAPFILE_ACTION" == "remove" ]]; then
            if ! confirm "Remove existing swap files and proceed?"; then
                die "aborted; no changes were made"
            fi
        else
            if ! confirm "Replace the swap file and proceed?"; then
                die "aborted; no changes were made"
            fi
        fi
    fi
}

show_dry_run_plan() {
    if [[ "$SWAPFILE_ACTION" == "none" ]]; then
        log "Swap files would be left unchanged because the insufficient-swap policy selected exit"
    elif [[ "$SWAPFILE_ACTION" == "remove" ]]; then
        log "Existing swap files would be removed; disk-backed swap would be retained"
        if ((FSTAB_CHANGED == 1)); then
            print_diff /etc/fstab "$FSTAB_PROPOSED_TMP" "fstab"
        else
            log "/etc/fstab requires no changes"
        fi
    elif ((FSTAB_CHANGED == 1)); then
        print_diff /etc/fstab "$FSTAB_PROPOSED_TMP" "fstab"
    else
        log "/etc/fstab requires no changes"
    fi

    if ((PERSIST_ZSWAP == 1)); then
        if ((GRUB_CHANGED == 1)); then
            print_diff /etc/default/grub "$GRUB_PROPOSED_TMP" "GRUB"
        else
            log "/etc/default/grub requires no changes"
        fi
        if ((${#INITRAMFS_MODULES[@]} > 0)); then
            if ((INITRAMFS_CHANGED == 1)); then
                print_diff /etc/initramfs-tools/modules "$INITRAMFS_PROPOSED_TMP" "initramfs module list"
            else
                log "/etc/initramfs-tools/modules already lists $INITRAMFS_MODULE"
            fi
        fi
    fi

    if ((APPLY_ZSWAP_NOW == 1)); then
        log "Dry run: zswap sysfs would be set to compressor=$ZSWAP_COMPRESSOR, max_pool_percent=$ZSWAP_POOL_PERCENT, enabled=Y"
    fi
    log "Dry run complete; no swap, configuration, sysfs, or backup changes were made"
}

swap_is_active() {
    local wanted="$1"
    local output name type decoded_name

    output="$(swapon --show=NAME,TYPE --noheadings --raw)" ||
        return 1
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        read -r name type _ <<<"$line"
        decoded_name="$(decode_swapon_name "$name")"
        if [[ "$type" == "file" && "$decoded_name" == "$wanted" ]]; then
            return 0
        fi
    done <<<"$output"
    return 1
}

rollback_swap_stage() {
    local active_file original temporary index rollback_failed=0

    log "Rolling back swap file changes"
    if ((NEW_SWAP_ACTIVE == 1)) && swap_is_active "$SWAP_FILE"; then
        if ! swapoff -- "$SWAP_FILE"; then
            warn "failed to disable new swap file during rollback: $SWAP_FILE"
            rollback_failed=1
        fi
    fi

    if ((NEW_TARGET_CREATED == 1)) && [[ -f "$SWAP_FILE" ]]; then
        if ! rm -f -- "$SWAP_FILE"; then
            warn "failed to remove new swap file during rollback: $SWAP_FILE"
            rollback_failed=1
        fi
    fi

    if [[ -n "$NEW_TEMP_PATH" && -e "$NEW_TEMP_PATH" ]]; then
        if ! rm -f -- "$NEW_TEMP_PATH"; then
            warn "failed to remove new temporary swap file: $NEW_TEMP_PATH"
            rollback_failed=1
        fi
    fi

    for ((index = ${#OLD_RENAME_ORIGS[@]} - 1; index >= 0; index--)); do
        original="${OLD_RENAME_ORIGS[index]}"
        temporary="${OLD_RENAME_TMPS[index]}"
        if [[ -e "$temporary" ]]; then
            if ! mv -f -- "$temporary" "$original"; then
                warn "failed to restore $original from $temporary"
                rollback_failed=1
            fi
        fi
    done

    for active_file in "${ACTIVE_FILE_SWAPS[@]}"; do
        if [[ -f "$active_file" ]] && ! swap_is_active "$active_file"; then
            if ! swapon -- "$active_file"; then
                warn "failed to reactivate old swap file: $active_file"
                rollback_failed=1
            fi
        fi
    done

    NEW_SWAP_ACTIVE=0
    NEW_TARGET_CREATED=0
    NEW_TEMP_PATH=""
    SWAP_ROLLBACK_NEEDED=0
    if ((rollback_failed == 1)); then
        warn "swap rollback was incomplete; inspect active swaps and hidden swap files"
        return 1
    fi
    log "Swap rollback complete"
}

apply_swap_file() {
    local active_file parent base old_temporary

    if ((${#ACTIVE_FILE_SWAPS[@]} > 0)); then
        SWAP_ROLLBACK_NEEDED=1
        for active_file in "${ACTIVE_FILE_SWAPS[@]}"; do
            log "Disabling existing swap file: $active_file"
            if ! swapoff -- "$active_file"; then
                warn "failed to disable swap file: $active_file"
                return 1
            fi
        done
    fi

    for active_file in "${CLEANUP_PATHS[@]}"; do
        [[ -f "$active_file" ]] || continue
        SWAP_ROLLBACK_NEEDED=1
        parent="$(dirname -- "$active_file")"
        base="$(basename -- "$active_file")"
        if ! old_temporary="$(mktemp -- "$parent/.${base}.xs-env-old.XXXXXX")"; then
            warn "failed to reserve a temporary path beside $active_file"
            return 1
        fi
        TEMP_FILES+=("$old_temporary")
        if ! old_temporary="$(canonicalize_path "$old_temporary")"; then
            warn "failed to canonicalize temporary path for $active_file"
            return 1
        fi
        log "Moving existing file aside: $active_file"
        if ! mv -f -- "$active_file" "$old_temporary"; then
            warn "failed to move existing file aside: $active_file"
            return 1
        fi
        OLD_RENAME_ORIGS+=("$active_file")
        OLD_RENAME_TMPS+=("$old_temporary")
    done

    if [[ "$SWAPFILE_ACTION" == "remove" ]]; then
        log "Existing swap files are disabled and moved aside for removal"
        return 0
    fi

    parent="$(dirname -- "$SWAP_FILE")"
    base="$(basename -- "$SWAP_FILE")"
    if ! NEW_TEMP_PATH="$(mktemp -- "$parent/.${base}.xs-env-new.XXXXXX")"; then
        warn "failed to create a temporary swap file in $parent"
        return 1
    fi
    TEMP_FILES+=("$NEW_TEMP_PATH")
    SWAP_ROLLBACK_NEEDED=1

    if [[ "$SWAP_FS_TYPE" == "btrfs" ]]; then
        if ! chattr +C -- "$NEW_TEMP_PATH"; then
            warn "failed to set nocow on the btrfs swap file"
            return 1
        fi
    fi

    log "Allocating ${SWAPFILE_SIZE_BYTES} bytes for $SWAP_FILE"
    if ! fallocate -l "$SWAPFILE_SIZE_BYTES" -- "$NEW_TEMP_PATH"; then
        warn "failed to allocate the swap file"
        return 1
    fi
    if ! chmod 600 -- "$NEW_TEMP_PATH"; then
        warn "failed to set swap file permissions"
        return 1
    fi
    if ! mkswap -- "$NEW_TEMP_PATH"; then
        warn "mkswap failed"
        return 1
    fi

    if ! mv -- "$NEW_TEMP_PATH" "$SWAP_FILE"; then
        warn "failed to install the new swap file at $SWAP_FILE"
        return 1
    fi
    NEW_TARGET_CREATED=1

    log "Enabling new swap file: $SWAP_FILE"
    if ! swapon -- "$SWAP_FILE"; then
        warn "failed to enable the new swap file"
        return 1
    fi
    NEW_SWAP_ACTIVE=1
    if ! swap_is_active "$SWAP_FILE"; then
        warn "new swap file did not appear in the active swap list"
        return 1
    fi
    log "New swap file is active: $SWAP_FILE"
}

commit_config() {
    local original="$1"
    local proposed="$2"
    local timestamp backup

    if ! timestamp="$(date -u +%Y%m%dT%H%M%SZ)"; then
        warn "failed to generate a backup timestamp for $original"
        return 1
    fi
    backup="${original}.bak.${timestamp}-${BASHPID}"
    if [[ -e "$backup" ]]; then
        warn "backup path already exists: $backup"
        return 1
    fi
    if ! cp -p -- "$original" "$backup"; then
        warn "failed to create backup: $backup"
        return 1
    fi
    if ! mv -- "$proposed" "$original"; then
        warn "failed to atomically replace $original; original remains unchanged"
        return 1
    fi

    CONFIG_BACKUP_PATH="$backup"
    log "Replaced $original atomically; backup: $backup"
}

delete_old_swap_files() {
    local index path status=0

    for ((index = 0; index < ${#OLD_RENAME_TMPS[@]}; index++)); do
        path="${OLD_RENAME_TMPS[index]}"
        if [[ -e "$path" ]]; then
            if ! rm -f -- "$path"; then
                warn "failed to remove old swap file: $path"
                status=1
            fi
        fi
    done
    if ((status == 0)); then
        OLD_RENAME_ORIGS=()
        OLD_RENAME_TMPS=()
    fi
    return "$status"
}

write_sysfs_value() {
    local parameter="$1"
    local value="$2"
    printf '%s' "$value" >"/sys/module/zswap/parameters/$parameter"
}

read_sysfs_value() {
    local parameter="$1"
    local value
    if ! IFS= read -r value <"/sys/module/zswap/parameters/$parameter"; then
        [[ -n "$value" ]] || return 1
    fi
    printf '%s' "$value"
}

zswap_enabled_value() {
    local value="$1"
    case "$value" in
        Y|y|1)
            printf 'Y'
            ;;
        *)
            printf 'N'
            ;;
    esac
}

restore_zswap_values() {
    local old_enabled="$1"
    local old_compressor="$2"
    local old_percent="$3"
    local restore_failed=0

    if ! write_sysfs_value enabled N; then
        warn "failed to disable zswap while restoring sysfs values"
        restore_failed=1
    fi
    if ! write_sysfs_value compressor "$old_compressor"; then
        warn "failed to restore zswap compressor"
        restore_failed=1
    fi
    if ! write_sysfs_value max_pool_percent "$old_percent"; then
        warn "failed to restore zswap max_pool_percent"
        restore_failed=1
    fi
    if [[ "$(zswap_enabled_value "$old_enabled")" == "Y" ]]; then
        if ! write_sysfs_value enabled Y; then
            warn "failed to restore zswap enabled state"
            restore_failed=1
        fi
    fi
    return "$restore_failed"
}

configure_zswap_now() {
    local old_enabled old_compressor old_percent normalized_old_enabled
    local current_compressor current_percent current_enabled current_enabled_raw

    if ! old_enabled="$(read_sysfs_value enabled)" ||
        ! old_compressor="$(read_sysfs_value compressor)" ||
        ! old_percent="$(read_sysfs_value max_pool_percent)"; then
        die "failed to read the current zswap sysfs values"
    fi
    normalized_old_enabled="$(zswap_enabled_value "$old_enabled")"

    current_compressor="$old_compressor"
    current_percent="$old_percent"
    current_enabled="$normalized_old_enabled"

    if [[ "$current_enabled" == "Y" &&
        ( "$current_compressor" != "$ZSWAP_COMPRESSOR" ||
            "$current_percent" != "$ZSWAP_POOL_PERCENT" ) ]]; then
        if ! write_sysfs_value enabled N; then
            die "failed to temporarily disable zswap"
        fi
        current_enabled="N"
    fi

    if [[ "$current_compressor" != "$ZSWAP_COMPRESSOR" ]]; then
        if ! write_sysfs_value compressor "$ZSWAP_COMPRESSOR"; then
            restore_zswap_values "$old_enabled" "$old_compressor" "$old_percent" || true
            die "failed to set zswap compressor"
        fi
    fi
    if [[ "$current_percent" != "$ZSWAP_POOL_PERCENT" ]]; then
        if ! write_sysfs_value max_pool_percent "$ZSWAP_POOL_PERCENT"; then
            restore_zswap_values "$old_enabled" "$old_compressor" "$old_percent" || true
            die "failed to set zswap max_pool_percent"
        fi
    fi
    if [[ "$current_enabled" != "Y" ]]; then
        if ! write_sysfs_value enabled Y; then
            restore_zswap_values "$old_enabled" "$old_compressor" "$old_percent" || true
            die "failed to enable zswap"
        fi
    fi

    if ! current_compressor="$(read_sysfs_value compressor)" ||
        ! current_percent="$(read_sysfs_value max_pool_percent)" ||
        ! current_enabled_raw="$(read_sysfs_value enabled)"; then
        restore_zswap_values "$old_enabled" "$old_compressor" "$old_percent" || true
        die "failed to read back zswap sysfs values"
    fi
    current_enabled="$(zswap_enabled_value "$current_enabled_raw")"
    if [[ "$current_compressor" != "$ZSWAP_COMPRESSOR" ||
        "$current_percent" != "$ZSWAP_POOL_PERCENT" ||
        "$current_enabled" != "Y" ]]; then
        restore_zswap_values "$old_enabled" "$old_compressor" "$old_percent" || true
        die "zswap readback verification failed (enabled=$current_enabled compressor=$current_compressor max_pool_percent=$current_percent)"
    fi
    log "zswap is enabled now: compressor=$current_compressor max_pool_percent=$current_percent"
}

report_partial_state() {
    local reason="$1"

    warn "$reason"
    if ((SKIP_SWAP_CONFIG == 1)); then
        warn "swap-file configuration was skipped; existing disk-backed swap was left unchanged"
    elif swap_is_active "$SWAP_FILE"; then
        warn "swap file is active: $SWAP_FILE"
    else
        warn "swap file is not active: $SWAP_FILE"
    fi
    if [[ -n "$FSTAB_BACKUP" ]]; then
        warn "fstab backup: $FSTAB_BACKUP"
    fi
    if [[ -n "$GRUB_BACKUP" ]]; then
        warn "GRUB backup: $GRUB_BACKUP"
    fi
    if [[ -n "$INITRAMFS_BACKUP" ]]; then
        warn "initramfs module-list backup: $INITRAMFS_BACKUP"
    fi
    warn "completed configuration stages were retained"
}

main() {
    parse_arguments "$@"
    validate_arguments
    check_root_os_and_interaction
    require_commands

    if ((DRY_RUN == 0)); then
        mkdir -p /run/lock
        exec 9>/run/lock/xs-env-swap.lock
        if ! flock -n 9; then
            die "another swap configuration process is running"
        fi
    fi

    check_zram
    detect_swap_state
    if [[ "$SWAPFILE_ACTION" == "full" || "$SWAPFILE_ACTION" == "difference" ]]; then
        check_swap_capacity
    fi
    validate_zswap

    if ((SKIP_SWAP_CONFIG == 0)); then
        prepare_fstab_proposal
    fi
    if ((PERSIST_ZSWAP == 1)); then
        prepare_grub_proposal
        if ((${#INITRAMFS_MODULES[@]} > 0)); then
            prepare_initramfs_proposal
        fi
    fi

    if ((SKIP_SWAP_CONFIG == 1 && PERSIST_ZSWAP == 0 && APPLY_ZSWAP_NOW == 0)); then
        if ((DRY_RUN == 1)); then
            show_dry_run_plan
        else
            log "Swap-file strategy selected exit; no zswap changes requested"
        fi
        return 0
    fi

    if ((DRY_RUN == 1)); then
        show_dry_run_plan
        return 0
    fi

    confirm_plan

    local result=0
    if [[ "$SWAPFILE_ACTION" != "none" ]]; then
        if ! apply_swap_file; then
            rollback_swap_stage || true
            die "swap file update failed; old swap files were restored when possible"
        fi

        if ((FSTAB_CHANGED == 1)); then
            if ! commit_config /etc/fstab "$FSTAB_PROPOSED_TMP"; then
                FSTAB_BACKUP=""
                rollback_swap_stage || true
                die "failed to commit /etc/fstab; old swap files were restored when possible"
            fi
            FSTAB_BACKUP="$CONFIG_BACKUP_PATH"
        fi

        SWAP_ROLLBACK_NEEDED=0
        if ! delete_old_swap_files; then
            result=1
        fi
    else
        log "Keeping existing swap files and disk-backed swap unchanged"
    fi

    if ((PERSIST_ZSWAP == 1 && GRUB_CHANGED == 1)); then
        if ! commit_config /etc/default/grub "$GRUB_PROPOSED_TMP"; then
            report_partial_state "failed to commit /etc/default/grub"
            exit 1
        fi
        GRUB_BACKUP="$CONFIG_BACKUP_PATH"
    fi

    if ((PERSIST_ZSWAP == 1 && INITRAMFS_CHANGED == 1)); then
        if ! commit_config /etc/initramfs-tools/modules "$INITRAMFS_PROPOSED_TMP"; then
            report_partial_state "failed to commit /etc/initramfs-tools/modules"
            exit 1
        fi
        INITRAMFS_BACKUP="$CONFIG_BACKUP_PATH"
    fi

    if ((PERSIST_ZSWAP == 1)); then
        if ! update-grub; then
            report_partial_state "update-grub failed"
            exit 1
        fi
        if ! update-initramfs -u -k all; then
            report_partial_state "update-initramfs failed"
            exit 1
        fi
        if ((${#INITRAMFS_MODULES[@]} > 0)) && ! verify_initramfs_modules; then
            report_partial_state "compression module verification failed after update-initramfs"
            exit 1
        fi
    fi

    if ((APPLY_ZSWAP_NOW == 1)); then
        if ! configure_zswap_now; then
            report_partial_state "failed to configure the running zswap instance"
            exit 1
        fi
    fi

    if ((result != 0)); then
        report_partial_state "swap and configuration succeeded, but some old swap files could not be removed"
        exit 1
    fi

    if [[ "$SWAPFILE_ACTION" == "remove" ]]; then
        log "Existing swap files were removed; disk-backed swap was retained"
    elif [[ "$SWAPFILE_ACTION" == "full" || "$SWAPFILE_ACTION" == "difference" ]]; then
        log "Swap configuration complete: $SWAP_FILE (${SWAPFILE_SIZE_BYTES} bytes)"
        if [[ "$SWAPFILE_ACTION" == "difference" ]]; then
            log "Swap file uses the requested-minus-existing size: ${SWAPFILE_SIZE_BYTES} bytes"
        fi
    fi
    if ((PERSIST_ZSWAP == 1)); then
        log "zswap persistence is configured; reboot is required"
    fi
    if [[ "$SWAPFILE_ACTION" == "none" ]]; then
        log "Existing disk-backed swap was left unchanged"
    fi
}

trap on_exit EXIT
trap 'exit 130' INT TERM HUP

main "$@"
