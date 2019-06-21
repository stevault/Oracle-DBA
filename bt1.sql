declare

   v_count number(3);

begin

  for i in (select table_name, index_name
		from dba_indexes where table_owner = 'DW_MAPI_LOG') loop

      select count(1) into v_count from (
	select table_name, columN_name, columN_position from dba_ind_columns where table_owner = 'DW_MAPI_LOG' and table_name = i.table_name and index_name = i.index_name
	minus
	select table_name, columN_name, columN_position from dba_ind_columns@osdev where table_owner = 'DW_MAPI_LOG' and table_name = i.table_name);

     if v_count > 0 then
        dbms_output.put_line('index ' || i.index_name || ' is missing on table ' || i.table_name);
     end if;

  end loop;
 		
end;
/
