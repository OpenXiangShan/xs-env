# Install base dependencies

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
    sudo \
    vim \
    git \
    make \
    g++ \
    time \
    curl \
    ca-certificates \
    xz-utils \
    libreadline6-dev \
    libsdl2-dev \
    libgmp-dev \
    g++-riscv64-linux-gnu \
    zlib1g-dev \
    device-tree-compiler \
    flex \
    autoconf \
    bison \
    sqlite3 \
    libsqlite3-dev \
    zstd \
    libzstd-dev \
    python-is-python3 \
    python3-protobuf \
    python3-grpc-tools \
    python3-psutil \
    numactl
