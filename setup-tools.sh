# This script will setup tools used by XiangShan
# tested on ubuntu 20.04 Docker image

# make apt non-interactive to avoid tzdata prompt
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y \
    proxychains4 \
    shadowsocks-libev \
    vim \
    wget \
    git \
    tmux \
    make \
    g++ \
    clang \
    llvm \
    time \
    curl \
    libreadline6-dev \
    libsdl2-dev \
    g++-riscv64-linux-gnu \
    openjdk-11-jre \
    zlib1g-dev \
    device-tree-compiler \
    flex \
    autoconf \
    bison \
    sqlite3 \
    libsqlite3-dev \
    zstd \
    libzstd-dev

sh -c "curl -L https://github.com/com-lihaoyi/mill/releases/download/0.12.5/0.12.5 > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"

# We need to use Verilator 4.204+, so we install Verilator manually
source ./install-verilator.sh

# Install Rust (stable) using rustup
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source $HOME/.cargo/env
