#!/bin/bash
set -e

make write_bitstream LOCAL_ENV=1
make write_ddr
make fpga-run RUN_LOG=results/reference.log
