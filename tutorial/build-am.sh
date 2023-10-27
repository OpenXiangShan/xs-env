set -v

cd $AM_HOME
make clean
cd apps/coremark
make ARCH=riscv64-xs ITERATIONS=1
echo -e '\nOutput workload:'
ls build
    