col mb format 99999.99

select pool, 'ALL' name, count(1), sum(bytes)/1024/1024 mb
 from v$sgastat
where pool is not null
 group by pool
union
select pool, name , 1, bytes/1024/1024  mb
from v$sgastat
where pool is null
/
