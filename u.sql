<<<<<<< HEAD
=======
col name format a30
col password format a30

>>>>>>> 36c77cc814cf7271d265031bd579fd31256a91e1
select name, su.password, ltime, exptime, expiry_date ,astatus, account_status , profile
from sys.user$ su, dba_users u
where su.name = u.username 
and astatus != 0
and astatus != 9
<<<<<<< HEAD
order by exptime, ltime
=======
order by exptime
>>>>>>> 36c77cc814cf7271d265031bd579fd31256a91e1
/
