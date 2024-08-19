set -v

cd $AM_HOME
make clean
cd apps/coremark
make ARCH=riscv64-xs ITERATIONS=1 LINUX_GNU_TOOLCHAIN=1 TOTAL_DATA_SIZE=400
echo -e '\nOutput workload:'
ls build
