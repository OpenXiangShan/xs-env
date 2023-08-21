set -v

./emu -i hello.bin --diff $NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so 2>perf.err
