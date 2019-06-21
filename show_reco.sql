whenever sqlerror exit sql.sqlcode

set feed off ver off numw 8

select   DB_NAME
        ,round(a.PERCENT_SPACE_USED,2) PERCENT_SPACE_USED
        ,round(b.value/1024/1024) RECO_SIZE_MB
        ,a.NUMBER_OF_FILES
        ,(case
         when a.PERCENT_SPACE_USED > 75 then 'CRITICAL'
         when a.PERCENT_SPACE_USED between 50 and 75 then 'WARNING'
         when a.PERCENT_SPACE_USED < 50 then 'OK'
         end) STATUS,chr(10)
from
(select PERCENT_SPACE_USED,NUMBER_OF_FILES from V$RECOVERY_AREA_USAGE where FILE_TYPE='ARCHIVED LOG') a,
(select value from v$parameter where name='db_recovery_file_dest_size') b,
(select name db_name from v$database) c
/

REM set serveroutput off feedback off

declare
   v_space number := 0;

begin
  select percent_space_used into v_space from v$recovery_area_usage where percent_space_used < 50;

  dbms_output.put_line('PERCENT USED:' || v_space);

exception
  when no_data_found then
	dbms_output.put_line('ERROR'); 
	raise;
  when others        then
	null;

end;
/

