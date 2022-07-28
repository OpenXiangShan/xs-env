set -x
set -e

cd XiangShan

for i in {1..3}
do
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 1 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 2 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 3 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 4 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 5 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 10 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 15 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 20 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 30 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 40 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 50 2> /dev/zero
  xsrun ./build/emu -i ../nexus-am/apps/coremark/build/coremark-riscv64-xs.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so -e 0 --enable-fork --fork-interval 60 2> /dev/zero
done

