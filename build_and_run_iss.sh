cp riscv64-xs_defconfig NEMU/configs
make -C NEMU clean
make -C NEMU riscv64-xs_defconfig
make -C NEMU -j16
./NEMU/build/riscv64-nemu-interpreter -I 10000000000 -b linux-sdcard/bbl.bin

