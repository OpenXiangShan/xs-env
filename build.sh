set -x

make -C XiangShan emu CONFIG=MinimalL3DebugConfig NUM_CORES=2 EMU_TRACE=1 -j16

