export AHEAD_HOME=${XS_PROJECT_ROOT}/NEMU-ahead
cd ${NOOP_HOME}
${XS_PROJECT_ROOT}/tutorial/emu-oracle -i ${XS_PROJECT_ROOT}/tutorial/_492740000000_.gz -I 100000 --diff $NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so --force-dump-result 2> debug.log
