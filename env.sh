# This script will setup XiangShan environment variables

export XS_PROJECT_ROOT=$(dirname $(realpath $0))
export NEMU_HOME=$XS_PROJECT_ROOT/NEMU
export AM_HOME=$XS_PROJECT_ROOT/nexus-am
export NOOP_HOME=$XS_PROJECT_ROOT/XiangShan
export DRAMSIM3_HOME=$XS_PROJECT_ROOT/DRAMsim3

echo SET XS_PROJECT_ROOT: ${XS_PROJECT_ROOT}
echo SET NOOP_HOME \(XiangShan RTL Home\): ${NOOP_HOME}
echo SET NEMU_HOME: ${NEMU_HOME}
echo SET AM_HOME: ${AM_HOME}
echo SET DRAMSIM3_HOME: ${DRAMSIM3_HOME}
