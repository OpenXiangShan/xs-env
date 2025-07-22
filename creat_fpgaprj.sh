XS_PROJECT_HOME=$(pwd)

cd XiangShan
export NOOP_HOME=$(pwd)
make verilog CONFIG=FpgaDiffMinimalConfig PLDM=1 FPGA_DIFF=1 PLDM_ARGS="--difftest-config H"

cd difftest
export NOOP_HOME=$(pwd)
make difftest_verilog PROFILE=../build/generated-src/difftest_profile.json NUM_CORES=1 CONFIG=ESBIF
cp -r ./build ../

cd ../../env-scripts/xs_kmh_fpga_diff
make update_core_flist
make kmh

cd $XS_PROJECT_HOME
