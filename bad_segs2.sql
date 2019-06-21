-- list large indexes - could be candidates for rebuild

select * from (
 select s.owner, s.segment_type, s.segment_name, s.bytes/1024/1024 mb, s.tablespace_name
	, i.table_name
   from dba_segments s
	, dba_indexes i
  where 1=1
    and s.segment_name = i.index_name
    and s.owner = i.owner
    and s.owner not in ('SYS','SYSTEM','SYSDBA')
    and s.segment_type = 'INDEX'
    and s.bytes > 1024*1024*1024
  order by s.bytes desc
)
where rownum < 10
/
