set -v

cd $NEMU_HOME
make clean
make riscv64-xs_defconfig
make -j
make clean-softfloat
make riscv64-xs-ref_defconfig
make -j
