# This script will setup tools used by XiangShan
# tested on ubuntu 20/22/24.04 Docker image

set -euo pipefail

# make apt non-interactive to avoid tzdata prompt
export DEBIAN_FRONTEND=noninteractive

apt update
apt install -y \
    vim \
    wget \
    git \
    make \
    g++ \
    time \
    curl \
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

WITH_OPTIONAL_TOOLS=${WITH_OPTIONAL_TOOLS:-false}
if [ "$WITH_OPTIONAL_TOOLS" = true ]; then
    apt install -y \
        proxychains4 \
        htop \
        zsh \
        tmux \
        rsync
fi

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

# grallvm has better performace and is enabled by default
WITH_GRALLVMJDK=${WITH_GRALLVMJDK:-true}
WITH_OPENJDK=${WITH_OPENJDK:-false}
JDK_VERSION=21 # do not change this unless tested, XiangShan does not compile with JDK 25 yet
if [ "${WITH_GRALLVMJDK}" = true ]; then
    echo "Installing GraalVM JDK ${JDK_VERSION}..."

    case "$(uname -m)" in
        x86_64) ARCH="linux-x64" ;;
        aarch64) ARCH="linux-aarch64" ;;
        *) echo "Unsupported architecture for GraalVM JDK: $(uname -m)"; exit 1 ;;
    esac

    curl -LO https://download.oracle.com/graalvm/${JDK_VERSION}/latest/graalvm-jdk-${JDK_VERSION}_${ARCH}_bin.tar.gz
    mkdir -p /opt/graalvm-jdk-${JDK_VERSION}
    tar -xzf graalvm-jdk-${JDK_VERSION}_${ARCH}_bin.tar.gz -C /opt/graalvm-jdk-${JDK_VERSION} --strip-components=1
    rm graalvm-jdk-${JDK_VERSION}_${ARCH}_bin.tar.gz

    echo "Hint: please add the following lines to your ~/.bashrc or ~/.zshrc to use GraalVM JDK ${JDK_VERSION}:"
    echo 'export PATH="/opt/graalvm-jdk-'${JDK_VERSION}'/bin:${PATH}"'
    echo 'export JAVA_HOME="/opt/graalvm-jdk-'${JDK_VERSION}'"'

    export PATH="/opt/graalvm-jdk-${JDK_VERSION}/bin:${PATH}"
    export JAVA_HOME="/opt/graalvm-jdk-${JDK_VERSION}"
fi
# if WITH_GRALLVMJDK is false, fall-back to openjdk,
# or WITH_OPENJDK is explicitly set to true, install openjdk as well
if [ "${WITH_GRALLVMJDK}" != true ] || [ "${WITH_OPENJDK}" = true ]; then
    echo "Installing OpenJDK ${JDK_VERSION}..."
    apt install -y openjdk-${JDK_VERSION}-jre
fi

sh -c "curl -L https://repo1.maven.org/maven2/com/lihaoyi/mill-dist/1.0.4/mill-dist-1.0.4-mill.sh > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"

# We need to use Verilator 4.204+, so we install Verilator manually
source ./install-verilator.sh
