col name format a30
col password format a30

select name, su.password, ltime, exptime, expiry_date ,astatus, account_status , profile
from sys.user$ su, dba_users u
where su.name = u.username 
and astatus != 0
and astatus != 9
order by exptime
/
