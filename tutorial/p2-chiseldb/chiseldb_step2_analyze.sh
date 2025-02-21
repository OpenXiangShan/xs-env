DB=$(ls -t $NOOP_HOME/build/*db | head -n 1)
sqlite3 $DB "select * from TLLog where ADDRESS=0x80040580" | sh $NOOP_HOME/scripts/cache/convert_tllog.sh