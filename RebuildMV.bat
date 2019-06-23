#!/bin/ksh

TOFILE=n
OUTPUTFILE=""

if [ $# -lt 2 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <mv owner> <mv name>"
  exit 2
fi

MV_OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
MV_NAME=`echo $2 | awk '{ printf(toupper($1)) }'`
MV_FILE=${MV_OWNER}.${MV_NAME}.sql
shift; shift

TMPDIR=/var/tmp/
MV_DIR=/home/oracle/awdba/mv/bak

rm -f $TMPDIR/$MV_FILE

while [ $# -ge 1 ]
do

   opt=$1

   case $opt in 
     -f) TOFILE=y; OUTPUTFILE=$MVBAKDIR/${MV_OWNER}.${MV_NAME}.sql ; shift ;;
      *) echo -e "\nI don't recognize options $opt."; 
   esac

done 

echo "whenever sqlerror exit sql.sqlcode" > $TMPDIR/$MV_FILE

BackupObj.sh $MV_OWNER $MV_NAME MATERIALIZED_VIEW -v -d -o | sed 's/(.*)$//1' | sed 's/AS SELECT .* FROM/as select * from/' >> $TMPDIR/$MV_FILE
[ $? -ne 0 ] && exit 1

BackupObjIdx.sh $MV_OWNER $MV_NAME -mv >> $TMPDIR/$MV_FILE
[ $? -ne 0 ] && exit 1

if [ "$TOFILE" != "y" ]; then
   cat $TMPDIR/$MV_FILE
   rm $TMPDIR/$MV_FILE
else
   mv $TMPDIR/$MV_FILE $MV_DIR
fi

exit 0

