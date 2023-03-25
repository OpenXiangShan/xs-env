cd $NEMU_HOME

mkdir -p $NEMU_HOME/tutorial_simpoint/cluster/stream
export CLUSTER=$NEMU_HOME/tutorial_simpoint/cluster/stream

./resource/simpoint/simpoint_repo/bin/simpoint \
    -loadFVFile ./tutorial_simpoint/profiling/simpoint_bbv.gz \
    -saveSimpoints $CLUSTER/simpoints0 \
    -saveSimpointWeights $CLUSTER/weights0 \
    -inputVectorsGzipped \
    -maxK 3 \
    -numInitSeeds 2 \
    -iters 1000 \
    -seedkm 123456 \
    -seedproj 654321