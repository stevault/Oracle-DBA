
if [ $# -lt 2 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <mv owner> <mv name>"
  exit 2
fi

MV_OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
MV_NAME=`echo $2 | awk '{ printf(toupper($1)) }'`
BACKUPFILE=bak/${MV_OWNER}_${MV_NAME}.sql

if [ -f $BACKUPFILE ]; then
   echo "$BACKUPFILE exists... overwrite?\c"
   read yorn
   if [ "$yorn" != "y" -a "$yorn" != "Y" ]; then
      echo "will not overwrite $BACKUPFILE"
      exit 0
   fi
fi
      
echo "creating backup $BACKUPFILE."

echo "DROP MATERIALIZED VIEW ${MV_OWNER}.${MV_NAME} ;" > $BACKUPFILE

echo "

whenever sqlerror exit failure
whenever oserror exit failure
set lines 25000 pages 0 long 1000000 trimspool on longc 225000 verify off showmode off feed off

execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);

col x for a25000

select dbms_metadata.get_ddl('MATERIALIZED_VIEW','$MV_NAME','$MV_OWNER') x from dual;

" | sqlplus -s '/ as sysdba' >> $BACKUPFILE

retcode=$?
[ $retcode -ne 0 ] && exit 1

BackupObjIdx.sh $MV_OWNER $MV_NAME -mv >> $BACKUPFILE

ls -l $BACKUPFILE

exit $retcode

