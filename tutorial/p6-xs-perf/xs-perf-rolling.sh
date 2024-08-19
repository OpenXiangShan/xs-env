set -v -e

cd ${NOOP_HOME}/scripts/rolling
python3 rollingplot.py ${XS_PROJECT_ROOT}/tutorial/p6-xs-perf/xs-perf-rolling.db ipc
ls ${NOOP_HOME}/scripts/rolling/results