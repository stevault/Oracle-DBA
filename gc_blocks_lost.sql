set pages 9000

select 
 a.SNAP_ID,
 to_char(s.begin_interval_time,'DD-MON-YYYY HH24:MI:SS') beg_time,
 to_char(s.end_interval_time,'DD-MON-YYYY HH24:MI:SS') end_time,
 a.INSTANCE_NUMBER,
 a.VALUE 
 from dba_hist_sysstat a, dba_hist_snapshot s
 where a.snap_id = s.snap_id 
 and a.dbid = s.dbid 
 and a.instance_number = s.instance_number 
and a.stat_id = 500461751
order by a.snap_id, a.instance_number
/
