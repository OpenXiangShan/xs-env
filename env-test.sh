# This script will check if XiangShan develop environment has been setup correctly

# Setup XiangShan environment variables
source env.sh
# OPTIONAL: export them to .bashrc

# NutShell uses similiar develop environment, we use it to test
# if develop environment has been setup correctly
export NOOP_HOME=$(pwd)/NutShell

cd ${NEMU_HOME}

# CPT_restorer need -march=rv64gcbkvh support. Test here.
CPT_CROSS_COMPILE_LIST='riscv64-linux-gnu- riscv64-unknown-linux-gnu-'
for COMPILE in $CPT_CROSS_COMPILE_LIST; do
  echo | ${COMPILE}gcc -S -march=rv64gcbkvh -o /dev/null -x c -
  if [ $? -eq 0 ]; then
    CPT_CROSS_COMPILE=$COMPILE
	break
  fi
done
if [ -z $CPT_CROSS_COMPILE ]; then
  echo 'No supported RISC-V compiler found! riscv64[-unknown]-linux-gnu-gcc with -march=rv64gcbkvh support needed.'
  exit 1
fi
make riscv64-nutshell-ref_defconfig CPT_CROSS_COMPILE=${CPT_CROSS_COMPILE}
make

# Compile processor project
cd ${NOOP_HOME}
make init
make clean
# test if mill & Chisel has been installed correctlly
make verilog 
# test if verilator has been installed correctlly
make emu
# test verilator simulation
./build/emu -b 0 -e 0 -i ./ready-to-run/microbench.bin
