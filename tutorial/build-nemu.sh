set -v

cd $NEMU_HOME
make clean
make riscv64-xs_defconfig
make -j
