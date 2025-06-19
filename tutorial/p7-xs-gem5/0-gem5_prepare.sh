#!/usr/bin/env bash

pushd ../../ && source env.sh && popd

check_env() {
    if [[ -z "${gem5_home}" ]]; then
        echo "Error: No gem5_home found" 1>&2
        return 1
    fi
}

prepare_gem5() {
    git submodule update --init $gem5_home && \
    pushd $gem5_home && \
    cd ext/dramsim3 && \
    (stat DRAMsim3 || git clone https://github.com/umd-memsys/DRAMSim3.git DRAMsim3) && \
    cd DRAMsim3 && mkdir -p build && cd build && cmake .. && make -j `nproc` && \
    popd
}

build_gem5() {
    pushd $gem5_home && \
    scons build/RISCV/gem5.opt --gold-linker -j `nproc` && \
    popd
}

build_nemu_diff() {
    # Used for difftest and GCPT restorer
    # Validated NEMU commit for tutorial: 5a4f6fea209f4c5f02c978f9d81ad6a7749ebea4
    pushd $gem5_home && \
    cd ext && \
    (stat NEMU || (git clone https://github.com/OpenXiangShan/NEMU.git && \
        pushd NEMU && \
        git checkout 5a4f6fea209f4c5f02c978f9d81ad6a7749ebea4 && \
        git submodule update --init && popd)) && popd && \
    pushd $gem5_home/ext/NEMU && \
    NEMU_HOME=$gem5_home/ext/NEMU make clean && \
    NEMU_HOME=$gem5_home/ext/NEMU make riscv64-gem5-ref_defconfig CROSS_COMPILE=riscv64-linux-gnu- && \
    NEMU_HOME=$gem5_home/ext/NEMU make -j `nproc` && \
    popd
}

prepare_data_proc() {
    # Validated commit for tutorial: 4000c092b8bde21fd4aa493f9907fa100dbcb3fc
    (stat gem5_data_proc || git clone https://github.com/shinezyy/gem5_data_proc.git) && \
    pushd gem5_data_proc && \
    git reset --hard 4000c092b8bde21fd4aa493f9907fa100dbcb3fc && \
    pip3 install -r requirements.txt && \
    popd
}

check_env && prepare_gem5 && build_gem5 && build_nemu_diff && prepare_data_proc
