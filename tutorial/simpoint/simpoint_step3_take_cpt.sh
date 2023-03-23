cd $NEMU_HOME

rm -rf $NEMU_HOME/tutorial_simpoint/stream/take_cpt

./build/riscv64-nemu-interpreter \
    -b \
    -D tutorial_simpoint \
    -w stream \
    -C take_cpt \
    -S ./tutorial_simpoint/cluster \
    --checkpoint-interval 50000000 \
    ../tutorial/bin/stream-0xa0000.bin