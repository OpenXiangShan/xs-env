#!/bin/bash

# This script will setup XiangShan develop environment automatically

# Init submodules
git submodule update --init --recursive
# TODO: rocket submodules are not needed

# Setup XiangShan environment variables
source env.sh
# OPTIONAL: export them to .bashrc

echo XS_PROJECT_ROOT: ${XS_PROJECT_ROOT}
echo NEMU_HOME: ${NEMU_HOME}
echo AM_HOME: ${AM_HOME}
echo NOOP_HOME: ${NOOP_HOME}

cd ${NEMU_HOME}
make riscv64-xs-ref_defconfig
make -j

# Use riscv64-linux-gnu- toolchain by default
cd ${AM_HOME}/apps/coremark
make ARCH=riscv64-xs LINUX_GNU_TOOLCHAIN=1 -k

cd ${XS_PROJECT_ROOT}