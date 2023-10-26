set -ve

cd ${NOOP_HOME}/coupledL2
git apply ${XS_PROJECT_ROOT}/tutorial/chiseldb/cc_err.patch

cd ${NOOP_HOME}
make clean
make emu EMU_THREADS=4 WITH_CHISELDB=1 -j16

cp ${NOOP_HOME}/build/emu ${XS_PROJECT_ROOT}/tutorial/emu-cc-err

cd ${NOOP_HOME}/coupledL2
git apply -R ${XS_PROJECT_ROOT}/tutorial/chiseldb/cc_err.patch
