set -x

# build CoreMark
make -C nexus-am/apps/coremark ARCH=riscv64-xs

# build XS
make -C XiangShan clean
make -C XiangShan emu EMU_THREADS=8 -j16

