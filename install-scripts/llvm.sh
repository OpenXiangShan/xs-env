# Install LLVM toolchain from apt.llvm.org

set -euo pipefail

LLVM_VERSION=19 # do not change this unless tested

# GSIM requires clang 19+, and difftest PGO uses LLVM BOLT.
# The clang/bolt packages in Ubuntu apt repos might be too old (i.e. Ubuntu 24.04 ships with clang 18),
# so we install a fixed LLVM version from apt.llvm.org instead.
echo "Installing LLVM ${LLVM_VERSION} toolchain..."

LLVM_CODENAME="$(sed -n -e 's/^VERSION_CODENAME=//p' -e 's/^UBUNTU_CODENAME=//p' /etc/os-release | head -n 1 | tr -d '"')"
if [ -z "${LLVM_CODENAME}" ]; then
    echo "Unable to determine Ubuntu codename" >&2
    exit 1
fi
LLVM_SUITE="llvm-toolchain-${LLVM_CODENAME}-${LLVM_VERSION}"

install -d -m 0755 /etc/apt/keyrings
curl -fL --retry 3 https://apt.llvm.org/llvm-snapshot.gpg.key -o /etc/apt/keyrings/llvm.asc
printf 'deb [signed-by=/etc/apt/keyrings/llvm.asc] https://apt.llvm.org/%s/ %s main\n' "${LLVM_CODENAME}" "${LLVM_SUITE}" \
    > /etc/apt/sources.list.d/llvm-19.list

apt-get update
# clang: for clang, clang++, etc.
# bolt: for pgo
# llvm: for llvm-profdata (also for pgo)
apt-get install -y --no-install-recommends \
    -t "${LLVM_SUITE}" \
    clang-${LLVM_VERSION} \
    bolt-${LLVM_VERSION} \
    llvm-${LLVM_VERSION}

echo "Hint: By default, LLVM tools are available with the -${LLVM_VERSION} suffix, such as clang-${LLVM_VERSION} and llvm-profdata-${LLVM_VERSION}."
echo "Hint: To use LLVM tools without the -${LLVM_VERSION} suffix, add the following line to your ~/.bashrc or ~/.zshrc:"
echo 'export PATH="/usr/lib/llvm-'${LLVM_VERSION}'/bin:${PATH}"'

export PATH="/usr/lib/llvm-${LLVM_VERSION}/bin:${PATH}"
