select index_name, table_name, owner, status
from dba_indexes
where status not in ('VALID','N/A')
/

select 'alter index ' || owner || '.' || index_Name || ' rebuild;'
from dba_indexes
where status not in ('VALID','N/A')
/

