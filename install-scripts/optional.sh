# Install optional tools

set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y \
    proxychains4 \
    htop \
    zsh \
    tmux \
    rsync \
    wget
