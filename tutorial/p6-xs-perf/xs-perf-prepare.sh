set -v -e
dir="p6-xs-perf"

cd ${NOOP_HOME}
make clean
make emu EMU_THREADS=4 WITH_CHISELDB=1 WITH_ROLLINGDB=1 -j8 \
PGO_WORKLOAD=${NOOP_HOME}/ready-to-run/coremark-2-iteration.bin PGO_MAX_CYCLE=10000 PGO_EMU_ARGS=--no-diff LLVM_PROFDATA=llvm-profdata
cp ${NOOP_HOME}/build/emu ${XS_PROJECT_ROOT}/tutorial/${dir}/emu-xs-perf

./build/emu -i ./ready-to-run/coremark-2-iteration.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so --dump-db