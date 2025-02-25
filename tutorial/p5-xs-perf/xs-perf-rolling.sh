set -v -e
dir="p5-xs-perf"

cd ${NOOP_HOME}/scripts/rolling
python3 rollingplot.py ${XS_PROJECT_ROOT}/tutorial/${dir}/xs-perf-rolling.db ipc
ls ${NOOP_HOME}/scripts/rolling/results
