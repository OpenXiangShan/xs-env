#!/bin/bash

export NEMU_HOME=$XS_PROJECT_ROOT/NEMU
export SIMPOINT_HOME=$XS_PROJECT_ROOT/tutorial/p4-checkpoint
export NEMU=$NEMU_HOME/build/riscv64-nemu-interpreter
export GCPT=$SIMPOINT_HOME/gcpt/build/gcpt.bin
export SIMPOINT=$NEMU_HOME/resource/simpoint/simpoint_repo/bin/simpoint

export BBL_PATH=$SIMPOINT_HOME/gcpt/build
export LOG_PATH=$SIMPOINT_HOME/simpoint_result/logs
export RESULT=$SIMPOINT_HOME/simpoint_result
export profiling_result_name=simpoint-profiling
export PROFILING_RES=$RESULT/$profiling_result_name
export interval=$((50*1000*1000))
