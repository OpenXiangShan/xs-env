set -x
set -e

# Build DRAMsim3
cd DRAMsim3
mkdir -p build && cd build
cmake .. -DCOSIM=1
make -j10
cd ../..

# Build XiangShan
cd XiangShan
make emu WITH_DRAMSIM3=1 EMU_THREADS=8 -j10

