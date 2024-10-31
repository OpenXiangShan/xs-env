set -v

cd $NEMU_HOME
### If you are building NEMU for the first time,
### you will need to run the following command to configure it.
### Here we have configured it in advance.
# make menuconfig
make clean
make riscv64-xs_defconfig
make -j
make clean-softfloat
make riscv64-xs-ref_defconfig
make -j
