set -v

./emu -i hello.bin --diff $NEMU_HOME/build/riscv64-nemu-interpreter-so 2>perf.err
