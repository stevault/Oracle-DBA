#!/bin/ksh

if [ $# -lt 2 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <owner> <name>"
  exit 2
fi

OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
NAME=`echo $2 | awk '{ printf(toupper($1)) }'`

echo "

whenever sqlerror exit failure
whenever oserror exit failure
set lines 250 pages 0 trimspool on verify off showmode off feed off

col x for a25000

select 'grant ' ||  privilege || ' on ' || owner || '.' || table_name || ' to ' || grantee || ';'
from dba_tab_privs
where table_name = '$NAME'
and owner = '$OWNER';

" | sqlplus -s '/ as sysdba'

retcode=$?
exit $retcode

