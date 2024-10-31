set -v -e
dir="p7-constantin"

wld=${XS_PROJECT_ROOT}/tutorial/${dir}/maprobe-riscv64-xs.bin
cst=${XS_PROJECT_ROOT}/tutorial/${dir}/my_constantin.txt
### If you don't want to input it manually, you can replace the next line with this line
# cat $cst | ./emu -i $wld -I 1000 --diff ${NOOP_HOME}/ready-to-run/riscv64-nemu-interpreter-so 2> ${XS_PROJECT_ROOT}/tutorial/${dir}/constantin.err
./emu -i $wld -I 1000 --diff ${NOOP_HOME}/ready-to-run/riscv64-nemu-interpreter-so 2> ${XS_PROJECT_ROOT}/tutorial/${dir}/constantin.err
