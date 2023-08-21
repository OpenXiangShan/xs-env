set -v

xargs -I Eaddr sqlite3 $NOOP_HOME/build/*.db "select * from TLLOG where ADDRESS=Eaddr" | sh $NOOP_HOME/scripts/utils/parseTLLog.sh
