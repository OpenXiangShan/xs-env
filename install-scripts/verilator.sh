# Install verilator

# https://verilator.org/guide/latest/install.html

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

# NOTE: ccache is intentionally removed from the dependencies list, since:
#   1. it does not help XiangShan's build performance in most cases, as slight change in chisel result in significant change in cpp code
#   2. it introduces too much IO overhead

apt-get update
apt-get install -y git help2man perl python3 make autoconf g++ flex bison
apt-get install -y libgoogle-perftools-dev libjemalloc-dev numactl perl-doc
apt-get install -y libfl2 || true  # Ubuntu only (ignore if gives error)
apt-get install -y libfl-dev || true  # Ubuntu only (ignore if gives error)
apt-get install -y zlibc zlib1g zlib1g-dev || true  # Ubuntu only (ignore if gives error)

# setup-tools.sh installs the pinned LLVM release before invoking this script.
# do not use apt clang, veriator 5.050+ requires clang 18+, which is not available in Ubuntu 20.04/22.04 apt repos.
if ! command -v clang >/dev/null 2>&1; then
    echo "clang is required to build Verilator; run setup-tools.sh first to install the pinned LLVM release." >&2
    exit 1
fi

git clone https://github.com/verilator/verilator

# Every time you need to build:
unset VERILATOR_ROOT  # For bash
cd verilator

git checkout v5.048

autoconf        # Create ./configure script
# Configure and create Makefile
./configure CC=clang CXX=clang++ LINK=clang++ # We use clang as default compiler
make -j$(nproc)        # Build Verilator itself
make install

verilator --version
