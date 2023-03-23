cd $NEMU_HOME

git checkout asplos2023-tutorial
git submodule update --init
make clean
make tutorial_defconfig
make -j4

cd resource/gcpt_restore && make -j4
