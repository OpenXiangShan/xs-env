sqlite3 $NOOP_HOME/build/*.db "select * from TLLog where ADDRESS=0x800419c0" | sh $NOOP_HOME/scripts/cache/convert_tllog.sh