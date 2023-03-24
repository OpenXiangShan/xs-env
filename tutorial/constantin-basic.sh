cd ${NOOP_HOME}
echo "4\nblock_cycles_cache_0 11\nblock_cycles_cache_1 12\nblock_cycles_cache_2 13\nblock_cycles_cache_3 15\n" > constantin.txt
cat constantin.txt | ${XS_PROJECT_ROOT}/tutorial/emu-constantin -i ./ready-to-run/linux.bin --diff ./ready-to-run/riscv64-nemu-interpreter-so 2> /dev/null
