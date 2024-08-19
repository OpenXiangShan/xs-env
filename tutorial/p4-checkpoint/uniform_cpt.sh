#!/bin/bash

source simpoint_env.sh

uniform_cpt(){
    set -x
    workload=$1
    log=$LOG_PATH/uniform
    mkdir -p $log
    name="uniform"

    $NEMU ${BBL_PATH}/${workload}.bin \
        -D $RESULT -w stream -C $name      \
        -b -u --cpt-interval ${interval}   --dont-skip-boot         \
        -I 100000000   \
        > $log/stream-out.txt 2>${log}/stream-err.txt
}

export -f uniform_cpt

uniform_cpt gcpt
