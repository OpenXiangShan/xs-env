# This script will setup tools used by XiangShan
# tested on ubuntu 20.04 Docker image

# make apt non-interactive to avoid tzdata prompt
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y \
    proxychains4 \
    vim \
    wget \
    git \
    tmux \
    make \
    g++ \
    time \
    curl \
    libreadline6-dev \
    libsdl2-dev \
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
    rsync

# GSIM requires clang 19+
if apt list "clang*" | grep clang-19; then
    apt install -y clang-19
    apt install -y bolt-19 || echo "Skipping bolt-19 installation, not available in apt repos"
    for bin in $(ls /usr/bin/*-19); do
        base=$(basename $bin)
        alt=${base%-19}
        update-alternatives --install /usr/bin/$alt $alt /usr/bin/$base 100
        update-alternatives --set $alt /usr/bin/$base
    done
else
    echo "Warning: clang-19 is not available, falling back to default clang."
    echo "This may be because you are not using the Ubuntu version we recommend."
    apt install -y clang
    apt install -y llvm-bolt || echo "Skipping llvm-bolt installation, not available in apt repos"
fi

# openjdk has better performance with newer versions
apt install -y openjdk-21-jre || apt install -y openjdk-11-jre

sh -c "curl -L https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.0.4/mill-dist-1.0.4-mill.sh > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"

# We need to use Verilator 4.204+, so we install Verilator manually
source ./install-verilator.sh
