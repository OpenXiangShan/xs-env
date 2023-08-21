mkdir -p $NOOP_HOME/build

set -v

./emu-bug -i $AM_HOME/apps/coremark/build/coremark-riscv64-xs.bin --diff $NEMU_HOME/build/riscv64-nemu-interpreter-so -b 1200 -e 1700 --dump-wave
