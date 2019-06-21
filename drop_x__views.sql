select 'drop ' || object_type || ' sys.' || object_name || ';'
 from dba_objects
 where owner = 'SYS'
 and substr(object_name,1,2) = 'X_'
/
