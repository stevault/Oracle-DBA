
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
   else
      rm -f $BACKUPFILE
   fi
fi
      

BackupObj.sh $MV_OWNER $MV_NAME MATERIALIZED_VIEW -o -d
retcode=$?
[ $retcode -ne 0 ] && exit 1

BackupObjIdx.sh $MV_OWNER $MV_NAME -mv >> $BACKUPFILE | tee -a $BACKUPFILE
retcode=$?
[ $retcode -ne 0 ] && exit 1

ls -l $BACKUPFILE

exit $retcode

