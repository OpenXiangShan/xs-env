set -v

cd $NEMU_HOME
./build/riscv64-nemu-interpreter -b $AM_HOME/apps/coremark/build/coremark-riscv64-xs.bin