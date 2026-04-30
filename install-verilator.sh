# https://verilator.org/guide/latest/install.html

# NOTE: ccache is intentionally removed from the dependencies list, since:
#   1. it does not help XiangShan's build performance in most cases, as slight change in chisel result in significant change in cpp code
#   2. it introduces too much IO overhead

export DEBIAN_FRONTEND=noninteractive

apt-get install -y git help2man perl python3 make autoconf g++ flex bison
apt-get install -y libgoogle-perftools-dev libjemalloc-dev numactl perl-doc
apt-get install -y libfl2  # Ubuntu only (ignore if gives error)
apt-get install -y libfl-dev  # Ubuntu only (ignore if gives error)
apt-get install -y zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)

# we recommend using clang-19 for the moment, but it's not default behavior of ubuntu 24.04
# so check if clang is installed before actually calling apt install to avoid multiple versions conflict
if ! command -v clang >/dev/null 2>&1; then
    apt-get install -y clang
fi

git clone https://github.com/verilator/verilator

# Every time you need to build:
unset VERILATOR_ROOT  # For bash
cd verilator

git checkout v5.048

autoconf        # Create ./configure script
# Configure and create Makefile
./configure CC=clang CXX=clang++ LINK=clang++ # We use clang as default compiler
make -j8        # Build Verilator itself
make install

verilator --version
