#!/usr/bin/env bash

# pushd ../../ && source env.sh && popd

pushd $gem5_home && \
export GCBV_REF_SO=$gem5_home/../NEMU/build/riscv64-nemu-gem5-ref-so && \
mkdir -p util/xs_scripts/coremark && \
cd util/xs_scripts/coremark && \
$gem5_home/build/RISCV/gem5.opt $gem5_home/configs/example/xiangshan.py \
--raw-cpt --generic-rv-cpt=$NOOP_HOME/ready-to-run/coremark-2-iteration.bin && \
popd
