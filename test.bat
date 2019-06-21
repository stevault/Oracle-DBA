. /cloudsfs1/jenkins/OracleEnv.h

DB=$ORACLE_SID

######################################################

while [ $# -ge 1 ];do

  opt=$1
  shift

  case $opt in
     -d) DB=$1; shift ;;
      *) echo "I don't know what $opt is...\n" ; exit 2;;
  esac

done

######################################################

CONNSTR=${BLAPICONN}@${DB}


echo "

show user

set serveroutput on

whenever sqlerror exit sql.sqlcode

-- tracing enabled 2/27/2019
ALTER SESSION SET TRACEFILE_IDENTIFIER = "TEST";
alter session set sql_trace=true; 
--

select count(1) from CUSTOMER;

--begin
--  Process_BOA_Feed.mainloop ();
--end;
/

" | $ORACLE_HOME/bin/sqlplus -s $CONNSTR


