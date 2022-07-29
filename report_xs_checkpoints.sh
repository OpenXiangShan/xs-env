set -x
set -e

python3 env-scripts/perf/perf.py XiangShan/SPEC06_EmuTasks_SJENG_BASE_2022 \
  --recursive -o sjeng_pubs_baseline.csv

