export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=/u01/app/oracle/product/11\.2\.0\.4/dbhome_1
export ORACLE_SID=os_prd2
export PATH=$PATH:$ORACLE_HOME/bin:/usr/local/java/bin:/sbin:/bin
export NLS_LANG=AMERICAN_AMERICA.AL32UTF8
#echo "EXEC sp_export_to_mis_datamart_pol(1);" | /u01/app/oracle/product/11.2.0.4/dbhome_1/bin/sqlplus dw_api/dw_api@os_prd1
echo "
alter session set events '10046 trace name context forever, level 12';
EXEC asp_export_to_mis_datamart_pol(1);" | /u01/app/oracle/product/11.2.0.4/dbhome_1/bin/sqlplus dw_api/dw_api@os_prd1

