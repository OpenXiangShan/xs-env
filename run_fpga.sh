set -x
set -e

echo ""
echo "Please wait for xs_nanhu/xs_nanhu.runs/impl_1/runme.log"
echo "MUST check whether it says write_bitstream completed successfully"
echo "Then the bit is generated correctly."
echo "This step may take more than 15 hours."

# this is to check whether the bit is generated correctly
cat scripts_v2/xs_nanhu/xs_nanhu.runs/impl_1/runme.log | grep "write_bitstream completed successfully"

rm -rf my_bitstream
mkdir my_bitstream
cp scripts_v2/xs_nanhu/xs_nanhu.runs/impl_1/xs_fpga_top_debug.ltx my_bitstream/
cp scripts_v2/xs_nanhu/xs_nanhu.runs/impl_1/xs_fpga_top_debug.bit my_bitstream/

echo "Download bitstream to FPGA..."
echo "This may take more than 10 minutes..."
vivado -mode batch -source ~/resource/runfpga.tcl -tclargs my_bitstream/ ~/resource/gcc_166_yqh.txt

