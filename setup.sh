#!/bin/bash

# This script will setup XiangShan develop environment automatically

# Init submodules
git submodule update --init --recursive
# TODO: rocket submodules are not needed

# Setup XiangShan environment variables
source env.sh
# OPTIONAL: export them to .bashrc

# NutShell uses similiar develop environment, we use it to test
# if develop environment has been setup correctly
export NOOP_HOME=$(pwd)/NutShell

cd ${NEMU_HOME}
make defconfig riscv64-xs-ref_defconfig
make

cd ${AM_HOME}/apps/coremark
make ARCH=riscv64-xs -k

# Compile processor project
cd ${NOOP_HOME}
make init
make verilog # Optional: test if mill & Chisel has been installed correctlly
make emu # Optional: test if verilator has been installed correctlly

cd ${XS_PROJECT_ROOT}
export NOOP_HOME=$(pwd)/XiangShan
