cd $NEMU_HOME

./build/riscv64-nemu-interpreter \
    -b \
    --restore \
    -I 1000000 \
    `find tutorial_uniform/try/linux/0/ -type f -name "*.gz" | tail -1`