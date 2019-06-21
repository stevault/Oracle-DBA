#!/bin/ksh

. /cloudsfs1/jenkins/OracleEnv.h

# set constant values

REPOSITORY_DIR=/home/oracle/awdba/repo

# parse command line parameters

if [ $# -lt 1 ]; then 
   echo "ERROR: missing parameter(s)."
   echo "SYNTAX: $0 <dbname>"
   echo "   options:"
   echo "	-o owner"
   echo "	-i included object types"
   echo "	-x excluded object types"
   echo "	-t last_ddl_time"
   echo "	-c created"
   echo "	-v version_number"
   echo "	-n object names"
   echo "EXAMPLE: $0 os_st -o \"='DW_API'\" -t \"'TABLE','INDEX'\""
   exit 2
fi

DBNAME=$1
shift
MYCONN=awdba/awdba@$DBNAME

# parse command line options

OWNER_CLAUSE="= owner"
OBJINCL_CLAUSE="= object_type"
OBJEXCL_CLAUSE="= object_type"
LASTDDL_CLAUSE="= last_ddl_time"
CREATED_CLAUSE="= created"
OBJSET_VERSION=`date '+%Y%m%d'`
OBJECT_NAME="= object_name"
OWNEXCL_FIXED="'FOGLIGHTSP','ORACLE_OCM','AWDBA','EXFSYS','MDSYS','SYS','PUBLIC','SYSTEM','XDB','WMSYS','SYSMAN','SQLTXPLAIN','SQLTXADMIN','SPOTLIGHTSP','SPOTLIGHT','OUTLN','ORDSYS','MDSYS','DBSNMP'"
TYPEXCL_FIXED="'PACKAGE BODY','SYNONYM','JOB','LOB','TABLE PARTITION','INDEX PARTITION'"
FILENAME=""

while [ $# -ge 1 ]; do

   opt=$1

   case $opt in
      -o) shift; OWNER_CLAUSE="$1"; shift ;;
      -i) shift; OBJINCL_CLAUSE="$1"; shift ;;
      -x) shift; OBJEXCL_CLAUSE="$1"; shift ;;
      -t) shift; LASTDDL_CLAUSE="$1"; shift ;;
      -c) shift; CREATED_CLAUSE="$1"; shift ;;
      -v) shift; OBJSET_VERSION="$1"; shift ; OUTPUT_DIR=$REPOSITORY_DIR/$OBJSET_VERSION ;;
      -n) shift; OBJECT_NAME="$1"; shift ;;
      -f) shift; FILENAME="$1"; shift ;;
       *) echo "ERROR:  Unknown parameter $opt"; exit 2 ;;
   esac

done

# create directory, if it does not exist

if [ ! -d $OUTPUT_DIR ]; then
   echo "Creating output directory $OUTPUT_DIR"
   mkdir $OUTPUT_DIR
   ls -d $OUTPUT_DIR
fi

if [ ! -z "$FILENAME" ] ; then
    OUTPUT_FILE="-f $OUTPUT_DIR/$FILENAME"
else
    OUTPUT_FILE=""
fi

# generate a list of objects

OBJECT_LIST_SQL="
	 select distinct 'DumpObjDDL.sh ' || owner || ' ' || object_name || ' '
		 || case when object_type = 'MATERIALIZED VIEW' then 'MATERIALIZED_VIEW' else object_type end 
		 || ' -f ${DBNAME}_' || owner || '.' || object_name || '.sql'
		 || ' -i $DBNAME '
		 || ' -o '
		 || ' $OUTPUT_FILE' line 
	   from dba_objects
	  where owner $OWNER_CLAUSE
	    AND OWNER NOT IN ($OWNEXCL_FIXED)
	    AND OBJECT_TYPE NOT IN ($TYPEXCL_FIXED)
	    and object_type $OBJINCL_CLAUSE
	    and object_type $OBJEXCL_CLAUSE
	    and last_ddl_time $LASTDDL_CLAUSE
	    and created $CREATED_CLAUSE
	    and object_name $OBJECT_NAME 
"

#echo $OBJECT_LIST_SQL

echo "
set pages 0 lines 200 feedback off serveroutput on

begin

  for ObjList in ($OBJECT_LIST_SQL) loop

     dbms_output.put_line(ObjList.line);

  end loop;

end;
/

" | $ORACLE_HOME/bin/sqlplus -s $MYCONN | while read line
do
   echo $line
   $line
done




