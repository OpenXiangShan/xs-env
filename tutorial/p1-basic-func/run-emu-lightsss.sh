set -v

./emu-bug -i $AM_HOME/apps/coremark/build/coremark-1-iteration-riscv64-xs.bin --diff $NEMU_HOME/build/riscv64-nemu-interpreter-so --enable-fork 2> lightsss.err
