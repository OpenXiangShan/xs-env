#!/usr/bin/env bash

pushd ../../ >/dev/null && source env.sh >/dev/null && popd >/dev/null

pushd gem5_data_proc && \
mkdir -p results && \
export PYTHONPATH=`pwd` && \
python3 batch.py -s ../data/xs-model-l1bank -o gem5-cache-example.csv --cache&& \
python3 simpoint_cpt/compute_weighted.py \
    -r gem5-cache-example.csv \
    -j ../data/xs-model-l1bank/cluster-0-0.json \
    -o weighted.csv && \
popd
