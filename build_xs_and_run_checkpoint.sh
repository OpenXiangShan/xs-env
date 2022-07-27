# Clean the environment
cd XiangShan && make clean

# Build MinimalConfig XiangShan
make emu CONFIG=MinimalConfig -j16 EMU_TRACE=1

# Simulate XiangShan with a checkpoint
./build/emu -I 10000                                  \
  --diff ./ready-to-run/riscv64-nemu-interpreter-so   \
  -i ../output_top/test/coremarkpro/0/_1000000000_.gz \
  2> simulator_stderr.txt

