TMP=/var/tmp
BASE=`basename $0`
CURDATE=`date '+%Y%m%d%H%M%S'`
TMPFILE=$TMP/${BASE}_$$.tmp
SQLFILE=$TMP/${BASE}.sql

parse_top () {

rm -f $TMPFILE
top -b -n 1 -c -M > $TMPFILE

head -1 $TMPFILE | tail -1 | cut -d',' -f1 | read top dash CURTIME up UPTIMEDAYS days 
head -1 $TMPFILE | tail -1 | cut -d',' -f2 | read UPTIMEMINS
head -1 $TMPFILE | tail -1 | cut -d',' -f3 | read NUMUSERS users
head -1 $TMPFILE | tail -1 | cut -d',' -f4 | read load average LA1MIN
head -1 $TMPFILE | tail -1 | cut -d',' -f5 | read LA5MIN 
head -1 $TMPFILE | tail -1 | cut -d',' -f6 | read LA15MIN 
head -2 $TMPFILE | tail -1 | read tasks NUMTASKS total NUMTASKRUN running NUMTASKSLEEP sleeping NUMTASKSTOP stopped NUMZOMBIES zombie 
head -3 $TMPFILE | tail -1 | cut -d' ' -f2- | sed 's;[%,washuntidy];;g' | read CPU_USER_PCT CPU_SYS_PCT CPU_NICE_PCT CPU_IDLE_PCT etal 
head -4 $TMPFILE | tail -1  | sed 's;[ *]; ;g' | sed 's;,;;g' | read a MEM_TOTAL b MEM_USED c MEM_FREE d MEM_BUFF e 
head -5 $TMPFILE | tail -1 | read swap etal 

}

echo_sql () {

echo "insert into mytable (currdatetime, curtime, uptimedays, uptimemins, numusers, load_1min, load_5min, load_15min"
echo "NUMTASKS, NUMTASKRUN, NUMTASKSLEEP, NUMTASKSTOP, NUMZOMBIES,"
echo "CPU_USER_PCT, CPU_SYS_PCT, CPU_NICE_PCT, CPU_IDLE_PCT,"
echo "MEM_TOTAL, MEM_USED, MEM_FREE, MEM_BUFF"
echo ")"
echo "values (sysdate, '${CURTIME}', $UPTIMEDAYS, $UPTIMEMINS, $NUMUSERS, $LA1MIN, $LA5MIN, $LA15MIN"
echo "$NUMTASKS, $NUMTASKRUN, $NUMTASKSLEEP, $NUMTASKSTOP, $NUMZOMBIES,"
echo "$CPU_USER_PCT, $CPU_SYS_PCT, $CPU_NICE_PCT, $CPU_IDLE_PCT,"
echo "$MEM_TOTAL, $MEM_USED, $MEM_FREE, $MEM_BUFF"
echo ");" 

}

rm $SQLFILE

i=0
while [ $i -lt 10 ]; 
do

 let i=i+1
 parse_top
 echo_sql  >> $SQLFILE
 sleep 10

done

