./build/emu -i /nfs-nvme/home/share/checkpoints_profiles/spec06_rv64gcb_o2_20m/take_cpt/omnetpp_492740000000_0.497511/0/_492740000000_.gz -I 1000000  --force-dump-result 2> debug.log
cat debug.log| grep Bp
cat debug.log| grep cycle
