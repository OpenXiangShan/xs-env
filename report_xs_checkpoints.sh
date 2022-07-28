set -x
set -e

python3 env-scripts/perf/perf.py XiangShan/SPEC06_EmuTasks_SJENG_2022 \
  --recursive -o sjeng.csv

