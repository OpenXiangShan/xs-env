# This script will setup tools used by XiangShan
# tested on ubuntu 20/22/24.04 Docker image

set -euo pipefail

SCRIPT_PATH="${BASH_SOURCE[0]:-$0}"
SCRIPT_DIR="$(dirname "$(realpath "$SCRIPT_PATH")")"

# make apt non-interactive to avoid tzdata prompt
export DEBIAN_FRONTEND=noninteractive

# Default values, can be overridden by command line options below
TARGET=default

print_usage() {
    cat <<EOF
Usage: $0 [OPTIONS]
  --target TARGET        install only TARGET (all, base, optional, llvm, jdk, mill, verilator)
  -h, --help             show this help message
EOF
}

while [ $# -gt 0 ]; do
    case "$1" in
        --target)
            if [ $# -lt 2 ]; then
                echo "Missing value for --target" >&2
                print_usage
                exit 1
            fi
            TARGET="$2"
            shift
            ;;
        -h|--help)
            print_usage;
            exit 0 ;;
        *)
            echo "Unknown option: $1";
            print_usage;
            exit 1 ;;
    esac
    shift
done

run_target() {
    case "$1" in
        base)
            source "${SCRIPT_DIR}/install-scripts/base.sh"
            ;;
        llvm)
            source "${SCRIPT_DIR}/install-scripts/llvm.sh"
            ;;
        jdk)
            source "${SCRIPT_DIR}/install-scripts/jdk.sh"
            ;;
        mill)
            source "${SCRIPT_DIR}/install-scripts/mill.sh"
            ;;
        verilator)
            source "${SCRIPT_DIR}/install-scripts/verilator.sh"
            ;;
        gsim)
            source "${SCRIPT_DIR}/install-scripts/gsim.sh"
            ;;
        optional)
            source "${SCRIPT_DIR}/install-scripts/optional.sh"
            ;;
        all)
            run_target default
            run_target optional
            ;;
        default)
            # without optional tools
            run_target base
            run_target llvm
            run_target jdk
            run_target mill
            run_target verilator
            run_target gsim
            ;;
        *)
            echo "Unknown target: $1" >&2
            print_usage
            exit 1
            ;;
    esac
}

run_target "$TARGET"
