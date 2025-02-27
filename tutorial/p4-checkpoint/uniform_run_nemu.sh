
#!/bin/bash

source simpoint_env.sh
set -x
./emu -i `find $RESULT/uniform/stream -type f -name "*_.gz" | tail -1` --diff $NOOP_HOME/ready-to-run/riscv64-nemu-interpreter-so --max-cycles=50000 2>uniform.err