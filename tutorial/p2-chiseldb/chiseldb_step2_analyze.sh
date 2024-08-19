DB=$(ls -t $NOOP_HOME/build/*db | head -n 1)
sqlite3 $DB "select * from TLLog where ADDRESS=0x800419c0" | sh $NOOP_HOME/scripts/cache/convert_tllog.sh