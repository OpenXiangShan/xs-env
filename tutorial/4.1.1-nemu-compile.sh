export NEMU_HOME=~/PATH/TO/NEMU-ahead
make riscv64-xs-ahead-ref_defconfig
make -j16
export AHEAD_HOME=~/PATH/TO/NEMU-ahead
export NEMU_HOME=
