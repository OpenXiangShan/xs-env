set -v -e

# ~22s
cd ${NOOP_HOME}/scripts/top-down && python3 top_down.py -s /opt/SPEC06_EmuTasks_topdown -j /opt/SPEC06_EmuTasks_topdown.json
ls ${NOOP_HOME}/scripts/top-down/results

cp ${NOOP_HOME}/scripts/top-down/results/result.png ./topdown.png