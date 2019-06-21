col memtyp format a20
col value format 9,999,999,999,999
col name format a20

break on report

prompt ===============================================================================================
prompt PARAMETERS

select db.name, 'AMM' memtyp, p.name, to_number(p.value) value
  from v$spparameter p, v$database db
 where p.name in ('memory_target', 'memory_max_target')
/

select db.name, 'ASMM' memtyp, p.name, to_number(p.value) value
  from v$spparameter p, v$database db
 where p.name in ('sga_target', 'sga_max_size', 'pga_aggregate_target')
/

compute sum of value on report

select db.name, 'MANUAL' memtyp, p.name, to_number(p.value) value
  from v$spparameter p, v$database db
where p.name in ('db_cache_size', 'shared_pool_size', 'large_pool_size', 'java_pool_size')
order by p.name
/

prompt ===============================================================================================
prompt ACTUAL STATS

col name format a40
 
select nvl(pool,'db_cache_size et al') pool, sum(bytes) value 
from v$sgastat
group by pool
order by pool
/

clear computes

select *
from v$pgastat
where name in ('aggregate PGA target parameter',
		'aggregate PGA auto target',
		'maximum PGA allocated',
		'cache hit percentage')
/

