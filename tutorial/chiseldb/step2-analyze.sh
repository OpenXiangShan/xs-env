set -v

sqlite3 $NOOP_HOME/build/*.db "select * from TLLOG where ADDRESS=0x80000dc0" | sh $NOOP_HOME/scripts/utils/parseTLLog.sh
