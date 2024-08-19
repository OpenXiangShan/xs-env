# make coupledL2-test-l2l3-v3 run THREADS_BUILD=16 CXX_COMPILER=clang++-17
cd $TLT_HOME/run && ./tltest_v3lt 2>&1 | tee tltest_v3lt.log