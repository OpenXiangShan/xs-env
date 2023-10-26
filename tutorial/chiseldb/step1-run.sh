set -v -e

mkdir -p $NOOP_HOME/build

${XS_PROJECT_ROOT}/tutorial/emu-cc-err -i $NOOP_HOME/ready-to-run/microbench.bin --diff $NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so --dump-db 2> /dev/null
