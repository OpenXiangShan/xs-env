mkdir -p $NOOP_HOME/build
rm $NOOP_HOME/build/*.vcd

set -v

./emu-bug -i $AM_HOME/apps/coremark/build/coremark-1-iteration-riscv64-xs.bin --diff $NEMU_HOME/build/riscv64-nemu-interpreter-so -b 9000 -e 11000 --dump-wave
