#!/bin/ksh

if [ $# -lt 2 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <DBlink owner> <DBLink name>"
  exit 2
fi

DL_OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
DL_NAME=`echo $2 | awk '{ printf(toupper($1)) }'`
BACKUPFILE=bak/${DL_OWNER}_${DL_NAME}.sql

if [ -f $BACKUPFILE ]; then
   echo "$BACKUPFILE exists... overwrite (y or N)?"
   read yorn
   if [ "$yorn" != "y" -a "$yorn" != "Y" ]; then
      echo "will not overwrite $BACKUPFILE"
      exit 0
   fi
fi
      
echo "creating backup $BACKUPFILE."

echo "DROP DATABASE LINK ${DL_OWNER}.${DL_NAME} ;" > $BACKUPFILE

echo "

whenever sqlerror exit failure
whenever oserror exit failure
set lines 25000 pages 0 long 1000000 trimspool on longc 225000 verify off showmode off feed off

execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);

col x for a25000

select dbms_metadata.get_ddl('DB_LINK','$DL_NAME','$DL_OWNER') x from dual;

" | sqlplus -s '/ as sysdba' >> $BACKUPFILE

retcode=$?

ls -l $BACKUPFILE

exit $retcode

