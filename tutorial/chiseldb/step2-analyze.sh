set -v

DB_FILE=`find $NOOP_HOME/build/ -type f -name "*.db" | tail -1`

sqlite3 $DB_FILE "select * from TLLOG where ADDRESS=0x80008fc0" | sh $NOOP_HOME/scripts/cache/convert_tllog.sh
