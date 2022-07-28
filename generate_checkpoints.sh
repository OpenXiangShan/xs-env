cp riscv64-xs-cpt_defconfig NEMU/configs

make -C NEMU clean
make -C NEMU riscv64-xs-cpt_defconfig
make -C NEMU -j16

make -C NEMU/resource/gcpt_restore

./NEMU/build/riscv64-nemu-interpreter            \
  -I 10000000000 --cpt-interval 1000000000 -u -b \
  -D output_top -C test -w coremarkpro           \
  -r ./NEMU/resource/gcpt_restore/build/gcpt.bin \
  linux-sdcard-cpt/bbl.bin

