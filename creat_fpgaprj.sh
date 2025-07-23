XS_PROJECT_HOME=$(pwd)

cd XiangShan
export NOOP_HOME=$(pwd)
make verilog CONFIG=FpgaDiffMinimalConfig PLDM=1 FPGA_DIFF=1 PLDM_ARGS="--difftest-config H"
python ./difftest/scripts/st_tools/interface.py ./build/rtl/XSTop.sv --core --fpga

cd difftest
export NOOP_HOME=$(pwd)
make difftest_verilog PROFILE=../build/generated-src/difftest_profile.json NUM_CORES=1 CONFIG=ESBIF
python ./scripts/st_tools/interface.py ./build/rtl/GatewayEndpoint.sv
cp -r ./src/test/vsrc/fpga ./build/
cp -r ./build ../

cd ../../env-scripts/xs_kmh_fpga_diff
rm -rf ./xs_kmh
make update_core_flist
make kmh

cd $XS_PROJECT_HOME
