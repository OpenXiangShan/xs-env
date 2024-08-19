#!/bin/bash
source simpoint_env.sh
rm -rf $RESULT

profiling(){
    set -x
    workload=$1
    log=$LOG_PATH/profiling_logs
    mkdir -p $log

    $NEMU ${BBL_PATH}/${workload}.bin \
        -D $RESULT -w stream -C $profiling_result_name \
        -b --simpoint-profile --cpt-interval ${interval} \
        > >(tee $log/stream-out.txt) 2> >(tee ${log}/stream-err.txt)
}

export -f profiling

profiling gcpt