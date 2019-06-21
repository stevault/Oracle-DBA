define colmn=&col1


select 
   &&colmn
	, count(1)
 from gv$active_session_history
where sql_id = 'cjz4qb5db673b'
group by
   &&colmn
/

undefine col1

