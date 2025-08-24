#!/bin/bash
set -e

make clean-rtl
make fpga-rtl DUT=XiangShan
make fpga-host DUT=XiangShan

make clean-vivado
make vivado
make bitstream

echo "Vivado has started in background. The rebuild may take more than 10 hours."
echo "Run 'make open_vivado' to check current status of vivado."
