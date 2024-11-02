#!/usr/bin/env bash

pushd ../../ >/dev/null && source env.sh >/dev/null && popd >/dev/null

pushd gem5_data_proc && \
python3 batch.py \
  -s $gem5_home/util/xs_scripts/coremark \
  -t --topdown-raw && \
popd
