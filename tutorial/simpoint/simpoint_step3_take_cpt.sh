cd $NEMU_HOME

rm -rf $NEMU_HOME/tutorial_simpoint/stream/take_cpt

./build/riscv64-nemu-interpreter \
    -b \
    -D tutorial_simpoint \
    -C take_cpt \
    -w stream \
    -S ./tutorial_simpoint/cluster \
    --checkpoint-interval 50000000 \
    $XS_PROJECT_ROOT/tutorial/bin/stream-0xa0000.bin