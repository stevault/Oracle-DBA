#!/bin/ksh

if [ $# -lt 3 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <owner> <name> <object type> [ option(s) ]"
  echo " options:"
  echo " -o (overwrite generated file if it exists)"
  echo " -v (display SQL to stdout)"
  echo " -d (add drop statement before create)"
  echo " -f (filename)"
  exit 2
fi

OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
NAME=`echo $2 | awk '{ printf(toupper($1)) }'`
TYPE=`echo $3 | awk '{ printf(toupper($1)) }'`
echo bak/${OWNER}_${NAME}.sql | sed 's;\$;;g' | read BACKUPFILE
echo bak/${OWNER}_${NAME}.tmp| sed 's;\$;;g' | read tmpfile
shift; shift; shift

DB=$ORACLE_SID
SYSCONN=awdba/awdba

DROP=N
DISPLAY=N
OVERWRITE=N

while [ $# -ge 1 ]

    do
       opt=$1

       case $opt in 
         -o) OVERWRITE=Y ; shift ;;
         -v) DISPLAY=Y ; shift ;;
         -i) shift ; SYSCONN=awdba/awdba@$1 ; shift ;;
         -d) DROP=Y ; shift ;;
        -db) shift; DB=$1 ; shift ;;
         -f) BACKUPFILE=$2 ; shift ; shift ;;
	  *) echo "I don't recognize option $opt"; exit 2;;
       esac
    done



[ "$OVERWRITE" = "Y" ] && rm -f $BACKUPFILE

if [ -f $BACKUPFILE ]; then

   echo "$BACKUPFILE exists... overwrite?\c"
   read yorn
   if [ "$yorn" != "y" -a "$yorn" != "Y" ]; then
      echo "will not overwrite $BACKUPFILE"
      exit 0
   fi
fi

if [ $TYPE != 'MATERIALIZED_VIEW_LOG' ]; then
   [ "$DROP" = "Y" ] && echo "DROP `echo $TYPE | sed 's;_; ;g'` ${OWNER}.${NAME} ;" >> $BACKUPFILE
fi

echo "

whenever sqlerror exit failure
whenever oserror exit failure
set lines 25000 pages 0 long 1000000 trimspool on longc 225000 verify off showmode off feed off

REM execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);

col x for a25000

select dbms_metadata.get_ddl('$TYPE','$NAME','$OWNER') x from dual;
prompt /

" | sqlplus -s $SYSCONN@$DB  >> $BACKUPFILE

retcode=$?

if [ "$TYPE" = 'MATERIALIZED_VIEW_LOG' -a "$DROP" = "Y" ]; then
    grep CREATE $BACKUPFILE | head -1 | sed 's;CREATE;DROP;' > $tmpfile
    echo "/" >> $tmpfile
    cat $BACKUPFILE >> $tmpfile
    mv $tmpfile $BACKUPFILE
fi

if [ $DISPLAY = "Y" ]; then
    cat $BACKUPFILE
else
    ls -l $BACKUPFILE
fi

exit $retcode
