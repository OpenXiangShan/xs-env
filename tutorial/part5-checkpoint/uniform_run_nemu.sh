
#!/bin/bash

source simpoint_env.sh
set -x
$NEMU -b `find $RESULT/uniform/stream -type f -name "*_.gz" | tail -1` --restore -I 1000000
