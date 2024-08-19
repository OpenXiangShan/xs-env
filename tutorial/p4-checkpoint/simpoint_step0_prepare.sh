#!/bin/bash
set -x
cd $NEMU_HOME
git submodule update --init

cd $NEMU_HOME/resource/simpoint/simpoint_repo
make clean
make

cd $NEMU_HOME
make clean
make riscv64-xs-cpt_defconfig
make -j 8

cd $NEMU_HOME/resource/gcpt_restore
rm -rf $XS_PROJECT_ROOT/tutorial/p4-checkpoint/gcpt
make -C $NEMU_HOME/resource/gcpt_restore/ O=$XS_PROJECT_ROOT/tutorial/p4-checkpoint/gcpt  GCPT_PAYLOAD_PATH=$XS_PROJECT_ROOT/tutorial/p4-checkpoint/bin/stream_100000.bin