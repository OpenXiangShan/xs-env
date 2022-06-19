#!/bin/bash

# This script will setup XiangShan develop environment automatically

# Init submodules
git submodule update --init --recursive
# TODO: rocket submodules are not needed

# Setup XiangShan environment variables
source env.sh
# OPTIONAL: export them to .bashrc

cd ${NEMU_HOME}
make riscv64-xs-ref_defconfig
make -j

cd ${AM_HOME}/apps/coremark
make ARCH=riscv64-xs -k

cd ${XS_PROJECT_ROOT}