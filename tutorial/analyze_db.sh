printf "%d" 0x80000dc0 | xargs -I Eaddr \
	sqlite3 build/2023-03-25@07:41:37.db \
	"select * from TLLOG where ADDRESS=Eaddr" | \
	sh scripts/utils/parseTLLog.sh
