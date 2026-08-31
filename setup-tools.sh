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

# GSIM requires clang 19+, but 24.04 or older are using clang 18 or older by default
LLVM_VERSION=19 # do not change this
LLVM_PRIORITY=$((LLVM_VERSION * 10))
# decide what to install based on Ubuntu version
UBUNTU_VERSION=$(sed -n 's/^VERSION_ID="\{0,1\}\([^"]*\)"\{0,1\}$/\1/p' /etc/os-release)
UBUNTU_VERSION=${UBUNTU_VERSION:-0}
CLANG_CANDIDATE=$(apt-cache policy "clang-${LLVM_VERSION}" | sed -n 's/^[[:space:]]*Candidate:[[:space:]]*//p')
if dpkg --compare-versions "$UBUNTU_VERSION" ge 26.04; then
    echo "Ubuntu 26.04 or newer detected, using default clang and llvm-bolt from apt repos..."
    apt install -y clang
    apt install -y llvm-bolt || echo "Warning: llvm-bolt not available in apt repos, skipping installation. This may cause PGO to fail to run."
elif [ -n "$CLANG_CANDIDATE" ] && [ "$CLANG_CANDIDATE" != "(none)" ]; then
    echo "Ubuntu version older than 26.04 detected, using clang-${LLVM_VERSION} and bolt-${LLVM_VERSION}..."
    apt install -y "clang-${LLVM_VERSION}"
    apt install -y "bolt-${LLVM_VERSION}" || echo "Warning: bolt-${LLVM_VERSION} not available in apt repos, skipping installation. This may cause PGO to fail to run."

    for bin in /usr/bin/*-"${LLVM_VERSION}"; do
        # skip non-executable files
        if [ ! -f "$bin" ] || [ ! -x "$bin" ]; then
            continue
        fi
        # skip files not in /usr/lib/llvm-${LLVM_VERSION}/
        case "$(readlink -f -- "$bin")" in
            "/usr/lib/llvm-${LLVM_VERSION}/"*) ;;
            *) continue ;;
        esac

        name=$(basename "$bin")
        name=${name%-${LLVM_VERSION}} # remove the version suffix
        target="/usr/local/bin/${name}" # put in /usr/local/bin instead of /usr/bin to avoid conflicts with apt-installed default clang/llvm binaries

        if [ -e "$target" ] && ! update-alternatives --query "$name" >/dev/null 2>&1; then
            echo "Warning: $target already exists and is not managed by update-alternatives, skipping."
            echo "Hint: you may need to add the following lines to your ~/.bashrc or ~/.zshrc to use ${name} ${LLVM_VERSION}:"
            echo 'export PATH="/usr/lib/llvm-'${LLVM_VERSION}'/bin:${PATH}"'
            continue
        fi

        update-alternatives --install "$target" "$name" "$bin" "$LLVM_PRIORITY"
    done
else
    echo "Warning: Old Ubuntu version detected and clang-${LLVM_VERSION} is not available, falling back to default clang."
    echo "This may cause GSIM etc. fail to compile, please consider using our recommended Ubuntu version or Docker image."
    apt install -y clang
    apt install -y llvm-bolt || echo "Warning: llvm-bolt not available in apt repos, skipping installation. This may cause PGO to fail to run."
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
