# Install LLVM toolchain from apt.llvm.org

set -euo pipefail

# GSIM requires clang 19+, and difftest PGO uses LLVM BOLT.
# The clang/bolt packages in Ubuntu apt repos might be too old (i.e. Ubuntu 24.04 ships with clang 18),
# so we install a fixed LLVM version from apt.llvm.org instead.
UBUNTU_VERSION="$(sed -n -e 's/^VERSION_ID=//p' /etc/os-release | tr -d '"' | sed 's/\.//')"
UBUNTU_CODENAME="$(sed -n -e 's/^VERSION_CODENAME=//p' -e 's/^UBUNTU_CODENAME=//p' /etc/os-release | head -n 1 | tr -d '"')"
if [ -z "${UBUNTU_CODENAME}" ] || [ -z "${UBUNTU_VERSION}" ]; then
    echo "Unable to determine Ubuntu codename or version" >&2
    exit 1
fi

if [ "${UBUNTU_VERSION}" -ge 2604 ]; then
    # 26.04 does not have clang-19 in apt.llvm.org yet, use -21 to align with Ubuntu 26.04 LTS.
    LLVM_VERSION=21
else
    # Ship unified clang-19 on older Ubuntu releases.
    LLVM_VERSION=19
fi

echo "Installing LLVM ${LLVM_VERSION} toolchain..."
LLVM_SUITE="llvm-toolchain-${UBUNTU_CODENAME}-${LLVM_VERSION}"
LLVM_KEYRING="/etc/apt/keyrings/llvm.asc"

install -d -m 0755 /etc/apt/keyrings
curl -fL --retry 3 https://apt.llvm.org/llvm-snapshot.gpg.key -o "${LLVM_KEYRING}"
if [ "${UBUNTU_VERSION}" -ge 2604 ]; then
    # Use the DEB822 format required by Ubuntu 26.04's apt.
    cat > /etc/apt/sources.list.d/llvm.sources <<EOF
Types: deb
URIs: https://apt.llvm.org/${UBUNTU_CODENAME}/
Suites: ${LLVM_SUITE}
Components: main
Signed-By: ${LLVM_KEYRING}
EOF
else
    cat > /etc/apt/sources.list.d/llvm.list <<EOF
deb [signed-by=${LLVM_KEYRING}] https://apt.llvm.org/${UBUNTU_CODENAME}/ ${LLVM_SUITE} main
EOF
fi

# Prefer llvm.org packages over Ubuntu's default packages.
cat > /etc/apt/preferences.d/llvm.pref <<EOF
Package: clang-* bolt-* llvm-* libclang* libllvm* libbolt*
Pin: origin apt.llvm.org
Pin-Priority: 1001
EOF

apt-get update
# clang: for clang, clang++, etc.
# bolt, llvm, libclang-rt-dev: for llvm-bolt, llvm-profdata, etc.
# NOTE: llvm.org uses a different versioning scheme than Ubuntu, so we allow downgrades to install the pinned version.
apt-get install -y --no-install-recommends --allow-downgrades \
    clang-${LLVM_VERSION} \
    bolt-${LLVM_VERSION} \
    llvm-${LLVM_VERSION} \
    libclang-rt-${LLVM_VERSION}-dev

ln -sfnT "/usr/lib/llvm-${LLVM_VERSION}" /usr/local/llvm

echo "Hint: By default, LLVM tools are available with the -${LLVM_VERSION} suffix, such as clang-${LLVM_VERSION} and llvm-profdata-${LLVM_VERSION}."
echo "Hint: To use LLVM tools without the -${LLVM_VERSION} suffix, add the following line to your ~/.bashrc or ~/.zshrc:"
echo 'export PATH="/usr/local/llvm/bin:${PATH}"'

export PATH="/usr/local/llvm/bin:${PATH}"
