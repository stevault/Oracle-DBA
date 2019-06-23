###################################
# define GLOBAL variables

DSTAMP=`date '+%Y%m%d'`
SYSCONN="/ as sysdba"
DUMPDIRNAME=DUMPDIR
DUMPDIR=/mnt/oda_backups/dump
[ ! -d $DUMPDIR ] && mkdir $DUMPDIR 

###################################
# define functions

###########
Drop_Directory () {

SYSCONN="$1"
DIR_NAME="$2"

echo Dropping export destination directory...

echo "

whenever sqlerror exit sql.sqlcode
whenever oserror exit oscode
set serveroutput on

declare
  nodir EXCEPTION;
  pragma exception_init(nodir,-4043);

begin 
  execute immediate 'Drop Directory $DIR_NAME';

exception
  when nodir then
	 dbms_output.put_line('Warning - directory $DIR_NAME did not exist.');
  when others then raise;

end;
/

exit 0

" | $ORACLE_HOME/bin/sqlplus -s ${SYSCONN}

return $?

} 
###########
Create_Directory () {

SYSCONN="$1"
DIR_NAME="$2"
OUTDIR="$3"

echo Creating export destination directory...

echo "
whenever sqlerror exit sql.sqlcode
whenever oserror exit oscode

Create Directory $DIR_NAME as '$OUTDIR';

exit 0

" | $ORACLE_HOME/bin/sqlplus -s ${SYSCONN}

return $?

} 

###########
Export_Data () {

lSYSCONN="'$1'"
lDIR_NAME=$2

echo Exporting specified schema objects

expdp USERID="$lSYSCONN" \
	TABLES=${OWNER}.${TABLE} \
	DIRECTORY=${lDIR_NAME} \
	DUMPFILE=${OWNER}_${TABLE}_${DSTAMP}.dmp \
	LOGFILE=${OWNER}_${TABLE}_${DSTAMP}.log

return $?
}

###################################
# parse command-line parameters

if [ $# -lt 2 ]; then
   echo "ERROR: Missing parameters."
   echo "SYNTAX: $0 $OWNER $TABLE
   echo "EXAMPLE: $0 dw_st system_log
   exit 2
fi

OWNER=$1
TABLE=$2 
shift; shift

while [ $# -ge 1 ]
do
   case $1 in 
    -d) shift ; DUMPDIR=$1 ; shift ;;
     *) echo "no idea what option '$1' is..." ; exit 2 ;;
   esac

done


###################################
Drop_Directory "$SYSCONN" ${DUMPDIRNAME}
retcode=$?

if [ $retcode -ne 0 ]; then
   echo -e "\n\nERROR:  An error occurred dropping the $DUMPDIRNAME directory"
   exit 1
fi
 
###################################
Create_Directory "$SYSCONN" ${DUMPDIRNAME} "$DUMPDIR"
retcode=$?

if [ $retcode -ne 0 ]; then
   echo -e "\n\nERROR:  An error occurred creating the ${DUMPDIRNAME} directory."
   exit 1
fi
 
###################################
Export_Data "$SYSCONN" ${DUMPDIRNAME} ${EXPORT_FILE} ${EXPORT_LOG}
retcode=$?

if [ $retcode -ne 0 ]; then
   echo -e "\n\nERROR:  An error occurred during the export."
   exit 1
fi
 
###################################
exit 0

