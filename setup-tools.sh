# This script will setup tools used by XiangShan
# tested on ubuntu 20.04 Docker image

apt update
apt install proxychains4 shadowsocks-libev vim wget git tmux make gcc time curl libreadline6-dev libsdl2-dev gcc-riscv64-linux-gnu openjdk-11-jre zlib1g-dev device-tree-compiler flex autoconf bison sqlite3 libsqlite3-dev

# We need to use Verilator 4.204+, so we install Verilator manually
./install-verilator.sh

# Install mill
sh -c "curl -L https://github.com/com-lihaoyi/mill/releases/download/0.9.8/0.9.8 > /usr/local/bin/mill && chmod +x /usr/local/bin/mill"