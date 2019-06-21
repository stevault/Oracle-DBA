#!/bin/ksh

if [ $# -lt 2 ]; then
  echo "ERROR:  Missing parameters."
  echo "SYNTAX: $0 <mv owner> <mv name>"
  exit 2
fi

MV_OWNER=`echo $1 | awk '{ printf(toupper($1)) }'`
MV_NAME=`echo $2 | awk '{ printf(toupper($1)) }'`
MV_PREFIX=`echo $MV_NAME | cut -c1-3`

case $MV_PREFIX in

   MVI ) SRC_OWNER='IVOS_ST' ; SRC_SID=iv_prd1 ;;
   MVD ) SRC_OWNER='DW_ST'   ; SRC_SID=os_prd1 ;;
     * ) echo "I don't know what $MV_PREFIX is." ; exit 1 ;;

esac

SRC_NAME=`echo $MV_NAME | cut -c5-`

echo "Target Object: $MV_OWNER . $MV_NAME @ $ORACLE_SID"
echo "Source Object: $SRC_OWNER . $SRC_NAME @ $SRC_SID"


echo "

column table_name format a30
column index_name format a30
column column_name format a30
set lines 200 pages 60 

	select ic.table_name, ic.index_name, ic.column_position, ic.column_name
	  from dba_ind_columns ic, dba_indexes i
	 where ic.index_name = i.index_name
	   and ic.index_owner =i.owner
	   and i.table_name = '$SRC_NAME'
	 order by ic.table_name, ic.index_name, ic.column_position;

" | sqlplus -s awdba/awdba@$SRC_SID

echo "  select ic.table_name, ic.index_name, ic.column_name
	  from dba_ind_columns ic, dba_indexes i
	 where ic.index_name = i.index_name
	   and ic.index_owner =i.owner
	   and i.table_owner = '$MV_OWNER'
	   and i.table_name = '$MV_NAME';

" | sqlplus -s awdba/awdba@$ORACLE_SID



