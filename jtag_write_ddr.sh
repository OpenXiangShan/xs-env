vivado -mode tcl -source jtag_write_ddr.tcl -tclargs ./ready-to-run/microbench-xs-no-uart.txt

rm ./*.jou
rm ./*.log
