#!/bin/bash
set -e

BIT_DIR=$(realpath ./env-scripts/xs_kmh_fpga_diff/xs_kmh/xs_kmh.runs/impl_1)

echo
if ! ls "$BIT_DIR"/*.bit >/dev/null 2>&1; then
  echo "ERROR: No .bit file found in $BIT_DIR, please check if vivado is still incomplete"
  exit 1
else
  echo "Note: Find bit in $BIT_DIR"
  make write_bitstream LOCAL_ENV=1 FPGA_BIT_HOME=$BIT_DIR
  make write_ddr WORKLOAD=microbench
  make fpga-run HOST=./XiangShan/difftest/build/fpga-host WORKLOAD=microbench RUN_LOG=results/rebuild.log
fi
