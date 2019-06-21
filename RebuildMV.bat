#!/bin/ksh

DB=$ORACLE_SID


if [ $# -lt 2 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <mv owner> <mv name>"
  exit 2
fi

MV_OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
MV_NAME=`echo $2 | awk '{ printf(toupper($1)) }'`

shift; shift

######################################################

while [ $# -ge 1 ];do

  opt=$1
  shift

  case $opt in
     -d) DB=$1; shift ;;
      *) echo "I don't know what $opt is...\n" ; exit 2;;
  esac

done

######################################################

echo "whenever sqlerror exit sql.sqlcode"

BackupObj.sh $MV_OWNER $MV_NAME MATERIALIZED_VIEW -v -drop -o -d $DB | sed 's/(.*)$//1' | sed 's/AS SELECT .* FROM/as select * from/'
[ $? -ne 0 ] && exit 1

BackupObjIdx.sh $MV_OWNER $MV_NAME -mv -d $DB
[ $? -ne 0 ] && exit 1


