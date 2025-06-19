set -v -e

# ~22s
P5_DIR=$XS_PROJECT_ROOT/tutorial/p5-xs-perf
cd ${NOOP_HOME}/scripts/top-down && python3 top_down.py -s $P5_DIR/data/SPEC06_EmuTasks_topdown -j $P5_DIR/data/SPEC06_EmuTasks_topdown.json
ls ${NOOP_HOME}/scripts/top-down/results
