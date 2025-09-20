# https://verilator.org/guide/latest/install.html

export DEBIAN_FRONTEND=noninteractive

apt-get install -y git help2man perl python3 make autoconf g++ flex bison clang
apt-get install -y libgoogle-perftools-dev numactl perl-doc
apt-get install -y libfl2  # Ubuntu only (ignore if gives error)
apt-get install -y libfl-dev  # Ubuntu only (ignore if gives error)
apt-get install -y zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)

git clone https://github.com/verilator/verilator

# Every time you need to build:
unset VERILATOR_ROOT  # For bash
cd verilator

git checkout v5.040

autoconf        # Create ./configure script
# Configure and create Makefile
./configure CC=clang CXX=clang++ LINK=clang++ # We use clang as default compiler
make -j8        # Build Verilator itself
make install

verilator --version
