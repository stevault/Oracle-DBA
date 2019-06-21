. /cloudsfs1/jenkins/OracleEnv.h

echo "
exec dbms_stats.gather_schema_stats('IVOS_ST');
" | $ORACLE_HOME/bin/sqlplus -s awdba/awdba@iv_st

