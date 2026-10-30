# Install verilator

# https://verilator.org/guide/latest/install.html

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

VERILATOR_VERSION="v5.052"
WORKDIR="$(mktemp -d)"
# INSTALLDIR is /usr/local/share/verilator by default
INSTALL_DOCKER_WRAPPER=${INSTALL_DOCKER_WRAPPER:-"false"}

function cleanup {
    rm -rf ${WORKDIR}
}
trap cleanup EXIT

# NOTE: ccache is intentionally removed from the dependencies list, since:
#   1. it does not help XiangShan's build performance in most cases, as slight change in chisel result in significant change in cpp code
#   2. it introduces too much IO overhead
echo "Installing deps for verilator..."
apt-get update
apt-get install -y git help2man perl python3 make autoconf g++ flex bison
apt-get install -y libgoogle-perftools-dev libjemalloc-dev numactl perl-doc
apt-get install -y zlib1g zlib1g-dev liblz4-dev
apt-get install -y libfl2
apt-get install -y libfl-dev

# setup-tools.sh installs the pinned LLVM release before invoking this script.
# do not use apt clang, veriator 5.050+ requires clang 18+, which is not available in Ubuntu 20.04/22.04 apt repos.
if ! command -v clang >/dev/null 2>&1; then
    echo "clang is required to build Verilator; run setup-tools.sh first to install the pinned LLVM release." >&2
    exit 1
fi

echo "Cloning verilator ${VERILATOR_VERSION}..."
git clone https://github.com/verilator/verilator ${WORKDIR}
cd ${WORKDIR}
git checkout v5.052

echo "Compiling verilator ${VERILATOR_VERSION}..."
unset VERILATOR_ROOT
autoconf
./configure CC=clang CXX=clang++ LINK=clang++
make -j$(nproc)

echo "Installing verilator ${VERILATOR_VERSION}..."
make install

if [ "${INSTALL_DOCKER_WRAPPER}" = "true" ]; then
    echo "Installing verilator docker wrapper..."
    cp -f ${WORKDIR}/ci/docker/run/verilator-wrap.sh /usr/local/bin/verilator-wrap.sh
fi

verilator --version
