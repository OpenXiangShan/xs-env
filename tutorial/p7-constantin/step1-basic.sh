set -v -e
dir="p7-constantin"

cd ${NOOP_HOME}
wld=${XS_PROJECT_ROOT}/tutorial/${dir}/maprobe-riscv64-xs.bin
cst=${XS_PROJECT_ROOT}/tutorial/${dir}/my_constantin.txt
cat $cst | ./build/emu -i $wld -I 1000 --diff ./ready-to-run/riscv64-nemu-interpreter-so 2> ${XS_PROJECT_ROOT}/tutorial/${dir}/constantin.err
