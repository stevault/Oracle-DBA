--- show materialized view logs that aren't being maintained

 select owner, segment_type, segment_name, bytes/1024/1024 mb
   from dba_segments
  where owner not in ('SYS','SYSTEM','SYSDBA')
    and segment_name like 'MLOG%'
    and bytes > 1024*1024*1024
/
