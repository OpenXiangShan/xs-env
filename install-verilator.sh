# https://verilator.org/guide/latest/install.html

sudo apt-get install git perl python3 make autoconf g++ flex bison ccache clang
sudo apt-get install libgoogle-perftools-dev numactl perl-doc
sudo apt-get install libfl2  # Ubuntu only (ignore if gives error)
sudo apt-get install libfl-dev  # Ubuntu only (ignore if gives error)
sudo apt-get install zlibc zlib1g zlib1g-dev  # Ubuntu only (ignore if gives error)

git clone https://github.com/verilator/verilator

# Every time you need to build:
unsetenv VERILATOR_ROOT  # For csh; ignore error if on bash
unset VERILATOR_ROOT  # For bash
cd verilator
git pull        # Make sure git repository is up-to-date
# git tag         # See what versions exist
#git checkout master      # Use development branch (e.g. recent bug fixes)
#git checkout stable      # Use most recent stable release
#git checkout v{version}  # Switch to specified release version

# XiangShan uses Verilator v4.204
git checkout v4.204

autoconf        # Create ./configure script
# Configure and create Makefile
./configure CC=clang CXX=clang++ # We use clang as default compiler
make -j8        # Build Verilator itself
sudo make install

verilator --version