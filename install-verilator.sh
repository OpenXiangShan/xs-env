# https://verilator.org/guide/latest/install.html

sudo apt-get install git help2man perl python3 make autoconf g++ flex bison clang
sudo apt-get install libgoogle-perftools-dev numactl perl-doc
sudo apt-get install libfl2  # Ubuntu only (ignore if gives error)
sudo apt-get install libfl-dev  # Ubuntu only (ignore if gives error)
sudo apt-get install zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)

git clone https://github.com/verilator/verilator

# Every time you need to build:
unset VERILATOR_ROOT  # For bash
cd verilator

# XiangShan uses Verilator v5.020
git checkout v5.020

autoconf        # Create ./configure script
# Configure and create Makefile
./configure CC=clang CXX=clang++ # We use clang as default compiler
make -j8        # Build Verilator itself
sudo make install

verilator --version
