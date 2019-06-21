select 
	snap_id,
	snap_day,
	snap_start,
	snap_stop,
	elap_min,
	load,
	lpad(' ',load,'*') ldf
   from (
 select to_char(s.begin_interval_time,'HH24:MI:SS') snap_start
	, to_char(s.end_interval_time,'HH24:MI:SS') snap_stop
 	, to_char(s.begin_interval_time,'Day') snap_day
	, o.snap_id
 	, (24*60) * to_number(cast(s.end_interval_time as date) - cast(s.begin_interval_time as date)) elap_min
	, sum(case when stat_name = 'LOAD' then value end) load
   from dba_hist_osstat o, dba_hist_snapshot s
  where o.SNAP_ID = s.SNAP_ID
    and o.DBID = s.DBID
    and o.INSTANCE_NUMBER = s.INSTANCE_NUMBER
  group by 
	s.begin_interval_time , s.end_interval_time , o.snap_id
  order by o.snap_id
)
/
