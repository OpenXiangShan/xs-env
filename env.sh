# This script will setup XiangShan environment variables

export XS_PROJECT_ROOT=$(pwd)
export NEMU_HOME=$(pwd)/NEMU
export AM_HOME=$(pwd)/nexus-am
export NOOP_HOME=$(pwd)/XiangShan
export DRAMSIM3_HOME=$(pwd)/DRAMsim3
export TLT_HOME=$(pwd)/tl-test-new
export gem5_home=$(pwd)/gem5

echo SET XS_PROJECT_ROOT: ${XS_PROJECT_ROOT}
echo SET NOOP_HOME \(XiangShan RTL Home\): ${NOOP_HOME}
echo SET NEMU_HOME: ${NEMU_HOME}
echo SET AM_HOME: ${AM_HOME}
echo SET DRAMSIM3_HOME: ${DRAMSIM3_HOME}
echo SET TLT_HOME: ${TLT_HOME}
echo SET gem5_home: ${gem5_home}
