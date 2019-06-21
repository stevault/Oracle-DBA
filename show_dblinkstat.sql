select 
--	a.snap_id
--	trunc(s.begin_interval_time)
	trunc(s.begin_interval_time) snap_day
--	, a.instance_number
--	, a.stat_id
	, a.stat_name
--	, a.value , b.value
	, sum(b.value - a.value)/1024/1024 mb_diff
 from dba_hist_sysstat a, dba_hist_sysstat b, dba_hist_snapshot s
where a.snap_id = b.snap_id -1 
  and a.instance_number = b.instance_number
  and a.stat_id = b.stat_id
--
  and s.snap_id = a.snap_id
  and s.instance_number = a.instance_number
--
  and (a.stat_name = 'bytes sent via SQL*Net to dblink' or a.stat_name = 'bytes received via SQL*Net from dblink')
--
--  and trunc(s.begin_interval_time) >= trunc(sysdate)-8
group by
	trunc(s.begin_interval_time)
	, a.stat_name
order by
	a.stat_name
	, trunc(s.begin_interval_time)
/
