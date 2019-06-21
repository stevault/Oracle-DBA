with arch_by_hour as
(select to_char(first_time,'DD-MON') dy
	, trunc(first_time) first_date
	, case when to_char(first_time,'DY') in ('SAT','SUN') then 'WEEKEND' else 'WEEKDAY' end daytype
	, to_char(first_time,'hh24:') hr
	, (blocks*block_size)/1024/1024 mb
 from v$archived_log l
where l.dest_id = 1
 and first_time > trunc(sysdate) - 100
)
select
	md.md_hour
	, count(distinct md.md_date) dys
	, count(distinct md.md_hour) hrs
	, count(distinct dy) dys
	, count(1) dys
	, sum(mb) / count(1) avg_mb_per_hr
	, sum(mb) total_size
	, count(1) num_files
from arch_by_hour,
	( select curr_hr - (r.rnum/24) md_datehour
	 	, to_char(curr_hr - (r.rnum/24),'HH24:') md_hour
	 	, trunc(curr_hr - (r.rnum/24)) md_date
	   from (select to_date(to_char(sysdate,'DD-MON-YYYY HH24'),'DD-MON-YYYY HH24') curr_hr, rownum rnum
		   from dba_objects
		  where rownum < 24*100) r
	) md
where 1=1
  and md.md_date = first_date (+)
  and md.md_hour = hr (+)
--and daytype = 'WEEKDAY'
group by
	md.md_hour
order by
	md.md_hour
/
