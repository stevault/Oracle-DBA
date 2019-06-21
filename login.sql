set feedback off
--alter session set nls_date_format = 'DD-MON-YYYY HH24:MI:SS';
set feedback on

set lines 312 pages 72 trimspool on 

SET SQLPROMPT '_CONNECT_IDENTIFIER: _USER> '
col owner format a20
col grantee format a30
col index_name format a50
col segment_name format a50
col M_ROW$$ format a40
col CHANGE_VECTOR$$ format a40

column VALUE_COL_PLUS_SHOW_PARAM format A90

