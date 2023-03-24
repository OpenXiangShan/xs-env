cd $NEMU_HOME

rm -rf tutorial_simpoint

./build/riscv64-nemu-interpreter \
    -b \
    -D $NEMU_HOME/tutorial_simpoint \
    -C profiling \
    -w stream \
    --simpoint-profile \
    --interval 50000000 \
    $XS_PROJECT_ROOT/tutorial/bin/stream-0xa0000.bin