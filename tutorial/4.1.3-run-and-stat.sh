export AHEAD_HOME=${XS_PROJECT_ROOT}/NEMU-ahead
cd ${NOOP_HOME}
./build/emu -i ${XS_PROJECT_ROOT}/tutorial/_492740000000_.gz -I 1000000  --force-dump-result 2> debug.log

${XS_PROJECT_ROOT}/tutorial/emu-oracle-base -i ${XS_PROJECT_ROOT}/tutorial/_492740000000_.gz -I 1000000  --force-dump-result 2> debug-base.log
echo "Bp Oracle"
cat debug.log| grep Bp
echo "Bp Base"
cat debug-base.log| grep Bp
echo "Cycle Oracle"
cat debug.log| grep clock_cycle
echo "Cycle Base"
cat debug-base.log| grep clock_cycle
