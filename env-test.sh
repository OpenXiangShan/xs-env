# This script will check if XiangShan develop environment has been setup correctly

# Setup XiangShan environment variables
source env.sh
# OPTIONAL: export them to .bashrc

# NutShell uses similiar develop environment, we use it to test
# if develop environment has been setup correctly
export NOOP_HOME=$(pwd)/NutShell

# Compile processor project
cd ${NOOP_HOME}
make init
make clean
# test if mill & Chisel has been installed correctlly
make verilog 
# test if verilator has been installed correctlly
make emu EMU_CXX_EXTRA_FLAGS="-DFIRST_INST_ADDRESS=0x80000000" WITH_CHISELDB=0 
# test verilator simulation
./build/emu -b 0 -e 0 -i ./ready-to-run/microbench.bin