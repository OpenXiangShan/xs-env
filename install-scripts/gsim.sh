# Install gsim

set -euo pipefail

LLVM_VERSION=19 # not a must, but better keep consistent with llvm.sh

# Pin gsim version to provide a stable docker image release
GSIM_VERSION="master-2026-09-22-210689a"

echo "Installing deps for gsim..."
apt-get update
apt-get install -y \
    libgmp-dev

ARCH="$(uname -m)"
case "${ARCH}" in
    x86_64) GSIM_ARCH="X64" ;;
    aarch64) GSIM_ARCH="ARM64" ;;
    *) echo "Unsupported architecture for gsim: ${ARCH}"; exit 1 ;;
esac

GSIM_FILE=$(curl -s --retry 3 https://api.github.com/repos/OpenXiangShan/gsim/releases/tags/${GSIM_VERSION} | grep "name" | grep "gsim-clang${LLVM_VERSION}\.[0-9]\+\.[0-9]\+-${GSIM_ARCH}" | cut -d '"' -f 4)

if [ -z "${GSIM_FILE}" ]; then
    echo "Failed to get the gsim file name for ${GSIM_ARCH} from GitHub API"
    exit 1
fi

echo "Installing gsim ${GSIM_VERSION} for ${GSIM_ARCH}..."
curl -fL --retry 3 "https://github.com/OpenXiangShan/gsim/releases/download/${GSIM_VERSION}/${GSIM_FILE}" -o /usr/local/bin/gsim
chmod +x /usr/local/bin/gsim
