# Install gsim

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# Pin gsim version to provide a stable docker image release
GSIM_VERSION="master-2026-10-30-45a73d6"
WORKDIR="$(mktemp -d)"
INSTALLDIR="/usr/local/share/gsim"

function cleanup {
    rm -rf ${WORKDIR}
}
trap cleanup EXIT

echo "Installing deps for gsim..."
apt-get update
apt-get install -y \
    libgmp-dev \
    zlib1g-dev

echo "Cloning gsim ${GSIM_VERSION}..."
git clone https://github.com/OpenXiangShan/gsim ${WORKDIR}
cd ${WORKDIR}
git checkout ${GSIM_VERSION}

echo "Compiling gsim ${GSIM_VERSION}..."
make GSIM_INCLUDE_PATH=${INSTALLDIR}/include build-gsim -j$(nproc)

echo "Installing gsim ${GSIM_VERSION}..."
rm -rf /usr/local/share/gsim /usr/local/bin/gsim
mkdir -p /usr/local/share/gsim/bin /usr/local/share/gsim/include /usr/local/bin
cp -f build/gsim/gsim /usr/local/share/gsim/bin/gsim
cp -f include/gsimFst.h /usr/local/share/gsim/include/gsimFst.h
ln -s /usr/local/share/gsim/bin/gsim /usr/local/bin/gsim
gsim --version
