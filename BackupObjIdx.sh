#!/bin/ksh

if [ $# -lt 2 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <owner> <name> [ option(s) ]"
  echo " options:"
  echo " -d (add drop statement before create)"
  echo " -mv (skip rebuilding of I_SNAP index on materialized views)"
  exit 2
fi

OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
NAME=`echo $2 | awk '{ printf(toupper($1)) }'`

shift; shift

DROP=N
MV=N
DB=$ORACLE_SID

######################################################

while [ $# -ge 1 ];do

  opt=$1
  shift

  case $opt in
     -d) DB=$1; shift ;;
    -mv) MV=Y ;;
  -drop) DROP=Y ;;
      *) echo "I don't know what $opt is...\n" ; exit 2;;
  esac

done

######################################################

[ "$DROP" = "Y" ] && echo "DROP `echo $TYPE | sed 's;_; ;'` ${OWNER}.${NAME} ;"
[ "$MV" = "Y" ] && SKIP_PK="index_name not like 'I_SNAP%'" || SKIP_PK="1=1"

echo "

whenever sqlerror exit failure
whenever oserror exit failure
set lines 25000 pages 0 long 1000000 trimspool on longc 225000 verify off showmode off feed off

execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);

col x for a25000

select dbms_metadata.get_ddl('INDEX',i.index_name,i.owner) x
  from dba_indexes i
 where table_owner = '$OWNER'
   and $SKIP_PK
   and table_name = '$NAME';

" | sqlplus -s $SYSCONN@$DB

retcode=$?
exit $retcode

