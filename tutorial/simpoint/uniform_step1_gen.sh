cd $NEMU_HOME

rm -rf tutorial_uniform

./build/riscv64-nemu-interpreter \
    --cpt-interval 2000000 \
    -u \
    -b \
    -D tutorial_uniform \
    -C try \
    -w linux \
    -r ./resource/gcpt_restore/build/gcpt.bin \
    --dont-skip-boot \
    -I 3000000 \
    ./ready-to-run/linux-0xa0000.bin