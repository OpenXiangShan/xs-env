#!/bin/bash

source simpoint_env.sh

checkpoint(){
    set -x
    workload=$1

    export CLUSTER=$RESULT/cluster
    log=$LOG_PATH/checkpoint_logs
    mkdir -p $log
    $NEMU ${BBL_PATH}/${workload}.bin \
        -D $RESULT -w stream -C checkpoint \
        -b -S $CLUSTER --cpt-interval $interval \
        > >(tee $log/stream-out.txt) 2> >(tee $log/stream-err.txt)
}

export -f checkpoint

checkpoint gcpt
