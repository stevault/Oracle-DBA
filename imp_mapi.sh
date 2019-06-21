#!/bin/ksh

. /cloudsfs1/jenkins/OracleEnv.h

CONN=$SYSCONN@os_qa
DIR=OSDEVDIR
DIRNAME="/mnt/oda_backups/exp"
DUMP="OS_DEV_20151120_1241_EXP_SCHEMA.dmp"
LOG="OS_DEV_20151120_1241_EXP_SCHEMA.implog"

#echo "
#whenever sqlerror exit sql.sqlcode
# create or replace directory $DIR as '$DIRNAME'; " | sqlplus -s $CONN
#[ $? -ne 0 ] && exit 1

#echo "
#whenever sqlerror exit sql.sqlcode
# drop user dw_mapi cascade; "  | sqlplus -s $CONN
#[ $? -ne 0 ] && exit 1

#echo "
#whenever sqlerror exit sql.sqlcode
# drop user dw_mapi_log cascade; 
#"  | sqlplus -s $CONN
#[ $? -ne 0 ] && exit 1

#impdp $CONN DIRECTORY=$DIR DUMPFILE=$DUMP LOGFILE=$LOG SCHEMAS=DW_MAPI EXCLUDE=TABLE:\"IN \(\'MAPI_SYSTEM_LOG\'\)\"
#[ $? -ne 0 ] && exit 1

impdp $CONN DIRECTORY=$DIR DUMPFILE=$DUMP LOGFILE=$LOG TABLES=DW_MAPI.MAPI_SYSTEM_LOG CONTENT=METADATA_ONLY
[ $? -ne 0 ] && exit 1

impdp $CONN DIRECTORY=$DIR DUMPFILE=$DUMP LOGFILE=$LOG SCHEMAS=DW_MAPI_LOG
[ $? -ne 0 ] && exit 1

