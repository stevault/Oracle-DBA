select b.snap_id, b.dy, b.dt, b.tm
	, e.cpu - b.cpu cpu_used
from
 (
	 select s.snap_id, to_char(sn.begin_interval_time,'DAY') dy
		, to_char(sn.begin_interval_time,'DD-MON-YYYY') dt
		, to_char(sn.begin_interval_time,'HH24:MI') tm
--
		, sum(case when s.stat_id = 24469293 then s.value else 0 end) cpu
--
	   from dba_hist_sysstat s, dba_hist_snapshot sn
	  where s.snap_id = sn.snap_id
	    and sn.begin_interval_time > sysdate - 7
	  group by s.snap_id, to_char(sn.begin_interval_time,'DAY') 
		, to_char(sn.begin_interval_time,'DD-MON-YYYY') 
		, to_char(sn.begin_interval_time,'HH24:MI')
) b,
 (
	 select s.snap_id, to_char(sn.begin_interval_time,'DAY') dy
		, to_char(sn.begin_interval_time,'DD-MON-YYYY') dt
		, to_char(sn.begin_interval_time,'HH24:MI') tm
--
		, sum(case when s.stat_id = 24469293 then s.value else 0 end) cpu
--
	   from dba_hist_sysstat s, dba_hist_snapshot sn
	  where s.snap_id = sn.snap_id
	    and sn.begin_interval_time > sysdate - 7
	  group by s.snap_id, to_char(sn.begin_interval_time,'DAY') 
		, to_char(sn.begin_interval_time,'DD-MON-YYYY') 
		, to_char(sn.begin_interval_time,'HH24:MI')
) e
where e.snap_id - 1 = b.snap_id
order by b.snap_id
/
