set -v

./emu-cc-err -i $NOOP_HOME/ready-to-run/linux.bin --diff $NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so --dump-db 2>linux.err
