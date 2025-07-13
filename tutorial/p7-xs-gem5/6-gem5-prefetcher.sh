#!/usr/bin/env bash

pushd ../../ >/dev/null && source env.sh >/dev/null && popd >/dev/null

function run_baseline() {
    gem5_opt_path=$1
    pushd $gem5_home && \
    export LD_LIBRARY_PATH=$gem5_home/ext/dramsim3/DRAMsim3:$LD_LIBRARY_PATH && \
    export GCBV_REF_SO=$gem5_home/riscv64-nemu-interpreter-c1469286ca32-so && \
    mkdir -p util/xs_scripts/mcf_baseline && \
    cd util/xs_scripts/mcf_baseline && \
    $gem5_opt_path $gem5_home/configs/example/xiangshan.py \
    --generic-rv-cpt=$gem5_home/../tutorial/p7-xs-gem5/data/mcf_12253_0.137576_.zstd \
    --gcpt-restorer=$gem5_home/../tutorial/p7-xs-gem5/data/normal-gcb-restorer.bin \
    -I 300000 && \
    popd
}

function run_with_despacito_stream() {
    gem5_opt_path=$1
    pushd $gem5_home && \
    export LD_LIBRARY_PATH=$gem5_home/ext/dramsim3/DRAMsim3:$LD_LIBRARY_PATH && \
    export GCBV_REF_SO=$gem5_home/riscv64-nemu-interpreter-c1469286ca32-so && \
    mkdir -p util/xs_scripts/mcf_despacito_stream && \
    cd util/xs_scripts/mcf_despacito_stream && \
    $gem5_opt_path $gem5_home/configs/example/xiangshan.py \
    --generic-rv-cpt=$gem5_home/../tutorial/p7-xs-gem5/data/mcf_12253_0.137576_.zstd \
    --gcpt-restorer=$gem5_home/../tutorial/p7-xs-gem5/data/normal-gcb-restorer.bin \
    -I 300000 && \
    popd
}

function diff_result() {
    pushd $gem5_home > /dev/null && \
    echo "===== Results =====" && \
    echo -n "Baseline                IPC: " && \
    cat util/xs_scripts/mcf_baseline/m5out/stats.txt | grep "system.cpu.ipc" | tr -s ' ' | cut -d ' ' -f2 && \
    echo -n "Despactio Stream        IPC: " && \
    cat util/xs_scripts/mcf_despacito_stream/m5out/stats.txt | grep "system.cpu.ipc" | tr -s ' ' | cut -d ' ' -f2 && \
    echo -n "Baseline         L1D Misses: " && \
    cat util/xs_scripts/mcf_baseline/m5out/stats.txt | grep "system.cpu.dcache.ReadReq.misses::total" | tr -s ' ' | cut -d ' ' -f2 && \
    echo -n "Despactio Stream L1D Misses: " && \
    cat util/xs_scripts/mcf_despacito_stream/m5out/stats.txt | grep "system.cpu.dcache.ReadReq.misses::total" | tr -s ' ' | cut -d ' ' -f2 && \
    popd > /dev/null
}

function self_build_baseline() {
    if [ -f "$gem5_home/../tutorial/p7-xs-gem5/data/gem5.opt" ]; then
        return
    fi
    pushd $gem5_home && \
    cd .. && git submodule update --init gem5 && cd gem5 && \
    scons build/RISCV/gem5.opt --linker=mold -j `nproc` && \
    cp build/RISCV/gem5.opt ../tutorial/p7-xs-gem5/data/gem5.opt && \
    popd
}

function self_build_despacito_stream() {
    if [ -f "$gem5_home/../tutorial/p7-xs-gem5/data/gem5.opt.despacito_stream" ]; then
        return
    fi
    pushd $gem5_home && \
    cd .. && git submodule update --init gem5 && cd gem5 && \
    (git branch -D add_a_new_prefetcher >/dev/null 2>&1 || true) && \
    (git checkout -b add_a_new_prefetcher || true) && \
    git am -3 ../tutorial/p7-xs-gem5/DespacitoStream.patch && \
    scons build/RISCV/gem5.opt --linker=mold -j `nproc` && \
    cp build/RISCV/gem5.opt ../tutorial/p7-xs-gem5/data/gem5.opt.despacito_stream && \
    popd
}

self_build_baseline && self_build_despacito_stream && \
run_baseline `realpath data/gem5.opt` && \
run_with_despacito_stream `realpath data/gem5.opt.despacito_stream` && \
diff_result
