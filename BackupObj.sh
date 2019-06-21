#!/bin/ksh

DB=$ORACLE_SID

if [ $# -lt 3 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <owner> <name> <object type> [ option(s) ]"
  echo " options:"
  echo " -o (overwrite generated file if it exists)"
  echo " -v (display SQL to stdout)"
  echo " -d (add drop statement before create)"
  exit 2
fi

OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
NAME=`echo $2 | awk '{ printf(toupper($1)) }'`
TYPE=`echo $3 | awk '{ printf(toupper($1)) }'`
shift; shift; shift

DROP=N
DISPLAY=N
OVERWRITE=N

######################################################

while [ $# -ge 1 ]
do

  opt=$1
  shift

       case $opt in 
         -o) OVERWRITE=Y ;;
         -v) DISPLAY=Y ;;
         -f) BACKUPFILE=$1 ; shift ;;
      -drop) DROP=Y ;;
         -d) DB=$1 ; shift ;;
	  *) echo "I don't recognize option $opt"; exit 2;;
       esac

done

BACKUPFILE=bak/${OWNER}_${NAME}_${DB}.sql

[ "$OVERWRITE" = "Y" ] && rm -f $BACKUPFILE

if [ -f $BACKUPFILE ]; then

   echo "$BACKUPFILE exists... overwrite?\c"
   read yorn
   if [ "$yorn" = "y" -o "$yorn" = "Y" ]; then
      OVERWRITE=Y
   else
      echo "will not overwrite $BACKUPFILE"
      exit 0
   fi
fi

case $TYPE in
     "DB_LINK") Type="DATABASE LINK";;
             *) Type="$TYPE" ;;
esac

[ "$DROP" = "Y" ] && echo "DROP `echo $Type | sed 's;_; ;'` ${OWNER}.${NAME} ;" >> $BACKUPFILE

echo "

whenever sqlerror exit failure
whenever oserror exit failure
set lines 25000 pages 0 long 1000000 trimspool on longc 225000 verify off showmode off feed off serveroutput on

execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);

col x for a25000

select dbms_metadata.get_ddl('$TYPE','$NAME','$OWNER') x from dual;

declare
  nogrant EXCEPTION;
  pragma exception_init(nogrant, -31608);
begin
 for grant_stmt in (SELECT DBMS_METADATA.GET_DEPENDENT_DDL('OBJECT_GRANT', '$NAME','$OWNER') x FROM DUAL) loop
   dbms_output.put_line(grant_stmt.x);
 end loop;
exception
  when nogrant then null;
  when others then raise;
end;
/


" | sqlplus -s $SYSCONN@$DB >> $BACKUPFILE

retcode=$?

if [ $DISPLAY = "Y" ]; then
    cat $BACKUPFILE
else
    ls -l $BACKUPFILE
fi

exit $retcode

