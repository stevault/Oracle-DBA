execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'PRETTY',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'SQLTERMINATOR',true);
execute DBMS_METADATA.SET_TRANSFORM_PARAM(DBMS_METADATA.SESSION_TRANSFORM,'STORAGE',false);

declare

  v_owner varchar2(20) := 'DW_MAPI_LOG';
  v_sql varchar2(2000);

begin

for tab in (

select distinct ut.table_name
from dba_tables ut
       inner join dba_tab_columns utt on utt.table_name = ut.table_name and utt.column_name = 'MAPI_CHS_NUMBER'
       inner join dba_constraints uc on uc.table_name = ut.table_name and uc.constraint_type = 'P'
       inner JOIN dba_cons_columns ucc on uc.constraint_name = ucc.constraint_name and ucc.column_name = 'HISTORY_EFFECTIVE_DATE'
where uc.constraint_name is not null
and ut.owner = v_owner
and utt.owner = v_owner
and uc.owner = v_owner
and ucc.owner = v_owner) loop

   for ind in (select index_name from dba_indexes where owner= 'DW_MAPI_LOG' and table_name = tab.table_name) loop

   select dbms_metadata.get_ddl( OBJECT_TYPE=>'INDEX'
		, NAME => ind.index_name
		, SCHEMA => v_owner)
     into v_sql
     from dual;

     dbms_output.put_line(v_sql);

   end loop;

  end loop;

end; 




/
