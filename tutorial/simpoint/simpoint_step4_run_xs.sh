$XS_PROJECT_ROOT/tutorial/emu \
    -i `find $NEMU_HOME/tutorial_simpoint/ -type f -name "*.gz" | tail -1` \
    --diff $NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so \
    --max-cycles=100000