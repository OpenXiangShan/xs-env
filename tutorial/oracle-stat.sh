export AHEAD_HOME=${XS_PROJECT_ROOT}/NEMU-ahead
cd ${NOOP_HOME}

echo "Bp Oracle"
cat debug.log| grep Bp
echo "Bp Base"
cat ${XS_PROJECT_ROOT}/tutorial/debug-base.log| grep Bp
echo "Cycle Oracle"
cat debug.log| grep clock_cycle
echo "Cycle Base"
cat ${XS_PROJECT_ROOT}/tutorial/debug-base.log| grep clock_cycle
