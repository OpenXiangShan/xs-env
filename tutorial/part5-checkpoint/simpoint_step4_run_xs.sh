
#!/bin/bash

source simpoint_env.sh
set -x
$NEMU -b `find $RESULT/checkpoint/stream -type f -name "*_.gz" | tail -1` --diff $NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so --max-cycles=50000 2>simpoint.err

