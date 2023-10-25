set -v

cd ${NOOP_HOME}
make clean
make emu CONFIG=MinimalConfig MFC=1 -j8
