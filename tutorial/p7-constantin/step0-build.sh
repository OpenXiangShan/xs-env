set -v -e
dir="p7-constantin"

cd ${NOOP_HOME}/utility
git apply ${XS_PROJECT_ROOT}/tutorial/${dir}/utility.patch

cd ${NOOP_HOME}
make clean
## 1 normal compile
# make emu EMU_THREADS=4 WITH_CONSTANTIN=1 EMU_OPTIMIZE="" -j200
## 2 PGO opt compile
wld=${XS_PROJECT_ROOT}/tutorial/${dir}/maprobe-riscv64-xs.bin
cst=${XS_PROJECT_ROOT}/tutorial/${dir}/my_constantin.txt
cat $cst | make emu EMU_THREADS=4 WITH_CONSTANTIN=1 -j200 \
PGO_WORKLOAD=$wld PGO_MAX_CYCLE=100000 PGO_EMU_ARGS=--no-diff LLVM_PROFDATA=llvm-profdata

cp ${NOOP_HOME}/build/emu ${XS_PROJECT_ROOT}/tutorial/${dir}/emu

cd ${NOOP_HOME}/utility
git apply -R ${XS_PROJECT_ROOT}/tutorial/${dir}/utility.patch
