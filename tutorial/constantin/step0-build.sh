set -v -e

cd ${NOOP_HOME}/utility
git apply ${XS_PROJECT_ROOT}/tutorial/constantin/utility.patch

cd ${NOOP_HOME}
make clean
make emu EMU_THREADS=4 EMU_TRACE=1 WITH_CONSTANTIN=1 MFC=1 -j16

cp ${NOOP_HOME}/build/emu ${XS_PROJECT_ROOT}/tutorial/emu-constantin

cd ${NOOP_HOME}/utility
git apply -R ${XS_PROJECT_ROOT}/tutorial/constantin/utility.patch
