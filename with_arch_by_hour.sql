with arch_by_hour as
"select to_char(first_time,'DD-MON') dy
	, to_char(first_time,'hh24:') hr
	, sum(blocks*block_size)/1024/1024 mb
 from v$archived_log l
where first_time > trunc(sysdate)-10
  and l.dest_id = 1
group by 
	 to_char(first_time,'DD-MON') 
	, to_char(first_time,'hh24:')
order by 
	 to_char(first_time,'DD-MON') 
	, to_char(first_time,'hh24:') 
"
select hr
	, sum(mb) / count(1)
	, sum(mb) , count(1)
from arch_by_hour
group by hr
/
