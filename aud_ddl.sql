col OS_USERNAME format a15
col USERNAME format a10
col USERHOST format a25
col TERMINAL format a15
col OWNER format a10
col OBJ_NAME format a30
col ddl_time format a20
col action_name format a20

 select 
	to_char(timestamp,'DD-MON-YYYY HH24:MI:SS') ddl_time,
	OS_USERNAME,
	USERNAME,
	USERHOST,
	TERMINAL,
	action_name,
	OWNER,
	OBJ_NAME
   from dba_audit_trail
  where timestamp >= trunc(sysdate-7)
    and action not in (100,101,102)
  order by timestamp
/

