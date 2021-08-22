# https://verilator.org/guide/latest/install.html

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
./configure     # Configure and create Makefile
make -j         # Build Verilator itself
sudo make install

verilator --version