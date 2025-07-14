# This script will setup XiangShan environment variables for checkpoint
# See 07-checkpoint.ipynb

echo === xs-env ===
cd .. && source env.sh && cd -

# constant
export WORKLOAD=stream_100000
export CHECKPOINT_INTERVAL=$((50*1000*1000))

# path
export SIMPOINT_HOME=$TUTORIAL_HOME/07-checkpoint

export PAYLOAD_PATH=$READY2RUN_HOME/07-checkpoint

export GCPT_PATH=$SIMPOINT_HOME/gcpt
export LOG_PATH=$SIMPOINT_HOME/logs
export RESULT_PATH=$SIMPOINT_HOME/result

export PROFILING_RESULT_PATH=$RESULT_PATH/profiling

# binary
export NEMU=$NEMU_HOME/build/riscv64-nemu-interpreter
export GCPT=$GCPT_PATH/build/gcpt.bin
export SIMPOINT=$NEMU_HOME/resource/simpoint/simpoint_repo/bin/simpoint

echo === checkpoint-env ===
echo SET WORKLOAD: ${WORKLOAD}
echo SET CHECKPOINT_INTERVAL: ${CHECKPOINT_INTERVAL}
echo SET SIMPOINT_HOME: ${SIMPOINT_HOME}
echo SET PAYLOAD_PATH: ${PAYLOAD_PATH}
echo SET GCPT_PATH: ${GCPT_PATH}
echo SET LOG_PATH: ${LOG_PATH}
echo SET RESULT_PATH: ${RESULT_PATH}
echo SET PROFILING_RESULT_PATH: ${PROFILING_RESULT_PATH}
echo SET NEMU: ${NEMU}
echo SET GCPT: ${GCPT}
echo SET SIMPOINT: ${SIMPOINT}

# pre-check

mkdir -p ${SIMPOINT_HOME}

if [[ ! -d "${PAYLOAD_PATH}" ]]; then
    echo "${PAYLOAD_PATH} does not exist, make sure you have downloaded ready-to-run files from Github release"
    exit 1
fi
