REM drop database link msdb_DW_DEV2;

create database link msdb_DW_DEV connect to "TestOracleUser" identified by "superman" using 'msdb_dw_dev' 
/
