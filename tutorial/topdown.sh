set -v

cd ${XS_PROJECT_ROOT}/env-scripts/perf/top_down && python3 top_down.py -s /opt/SPEC06_EmuTasks_topdown/

ls ${XS_PROJECT_ROOT}/env-scripts/perf/top_down/results

