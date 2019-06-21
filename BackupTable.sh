#!/bin/ksh

TSTAMP=`date '+%Y%m%d'`
WHERECLAUSE=""
AUDITFILE=/dev/null
OVERWRITE=""

###################################
# define functions

###########
Recreate_Directory () {

SYSCONN="$1"
DIR_NAME="$2"
OUTDIR="$3"

echo "

whenever sqlerror exit sql.sqlcode
whenever oserror exit oscode
set serveroutput on

prompt Dropping export destination directory...

declare
  nodir EXCEPTION;
  pragma exception_init(nodir,-4043);

begin 
  execute immediate 'Drop Directory $DIR_NAME';

exception
  when nodir then
	 dbms_output.put_line('NOTE:  directory $DIR_NAME did not exist.');
  when others then raise;

end;
/

prompt Creating export destination directory...

create directory $DIR_NAME as '$OUTDIR';

" | $ORACLE_HOME/bin/sqlplus -s ${SYSCONN}

return $?

} 

###################################
# parse command-line parameters

if [ $# -lt 2 ]; then
   echo "ERROR: Missing parameters."
   echo "SYNTAX: $0 <owner> <table>"
   echo "EXAMPLE: $0 dw_st tmp_table"
   exit 2
fi

OWNER=$1
TABLE=$2 
shift ; shift

while [ $# -ge 1 ]; do

    opt=$1

    case $opt in
        -q) shift ; WHERECLAUSE="QUERY=\"${TABLE}:$1\"" ; shift ;;
        -o) OVERWRITE="REUSE_DUMPFILES=Y" ; shift ;;
        -d) shift ; SYSCONN=awdba/awdba@$1;  shift ;;
      -dir) shift ; ACTUALOUTDIR=$1;  shift ;;
         *) echo "$opt is not a valid option." ; exit 2 ;;
    esac

done

###################################

OUTDIR=/mnt/oda_backups/${ORACLE_DB}/exp
OUTDIRNAME=REFDUMP

EXPORT_FILE=${OWNER}_${TABLE}.dmp
EXPORT_LOG=${OWNER}_${TABLE}.explog

###################################
[ ! -d $OUTDIR ] && mkdir -p $OUTDIR

###################################
Recreate_Directory "$SYSCONN" ${OUTDIRNAME} "$OUTDIR" 1>$AUDITFILE 2>&1
retcode=$?

if [ $retcode -ne 0 ]; then
   echo -e "\n\nERROR:  An error occurred creating the ${OUTDIRNAME} directory."
   exit 1
fi
 
###################################
expdp USERID="$SYSCONN" \
	TABLES=${OWNER}.${TABLE} \
	$OVERWRITE \
	DIRECTORY=${DIR_NAME} \
	DUMPFILE=${EXPORT_FILE} \
	LOGFILE=${EXPORT_LOG}

#retcode=$?

if [ $retcode -ne 0 ]; then
   echo -e "\n\nERROR:  An error occurred during the export."
   exit 1
fi

if [ -d ${ACTUALOUTDIR} ]; then
	mv $OUTDIR/$EXPORT_FILE $ACTUALOUTDIR
	mv $OUTDIR/$EXPORT_LOG $ACTUALOUTDIR
fi


