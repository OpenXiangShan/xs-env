set -v -e
dir="p6-xs-perf"

spec_path=/opt/SPEC06_EmuTasks_topdown
json_path=/opt/SPEC06_EmuTasks_topdown.json
cd ${NOOP_HOME}/scripts/top-down && python3 top_down.py -s $spec_path -j $json_path

ls ${NOOP_HOME}/scripts/top-down/results