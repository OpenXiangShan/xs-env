export NEMU_HOME=${XS_PROJECT_ROOT}/NEMU-ahead
cd ${NEMU_HOME}
make riscv64-xs-ahead-ref_defconfig
make -j16
export AHEAD_HOME=${XS_PROJECT_ROOT}/NEMU-ahead
# redirect NEMU_HOME to difftest version
export NEMU_HOME=${XS_PROJECT_ROOT}/NEMU
