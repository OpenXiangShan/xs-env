#!/bin/bash

# This script will setup XiangShan develop environment automatically

# Init submodules
git submodule update --init --recursive
# TODO: rocket submodules are not needed

# Init tools
# tested on ubuntu 20.04 Docker image

apt update
apt install proxychains4 shadowsocks-libev vim wget git tmux make gcc time curl libreadline6-dev libsdl2-dev gcc-riscv64-linux-gnu openjdk-11-jre zlib1g-dev verilator device-tree-compiler
sh -c "curl -L https://github.com/com-lihaoyi/mill/releases/download/0.9.8/0.9.8 > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"

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
