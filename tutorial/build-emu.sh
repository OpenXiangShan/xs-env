set -v

cd ${NOOP_HOME}
make clean
make emu EMU_THREADS=4 EMU_TRACE=1 -j16

cp ${NOOP_HOME}/build/emu ${XS_PROJECT_ROOT}/tutorial/emu
