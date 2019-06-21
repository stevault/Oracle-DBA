create table a (an primary key, bn)
as select 2056, 848 from dual;
 
create table b (an primary key, bn, cn)
as select 2056, 1005, 'A' from dual;
 
BEGIN
  DBMS_COMPARISON.PURGE_COMPARISON(
    comparison_name => 'a_b'
  );
  DBMS_COMPARISON.DROP_COMPARISON(
    comparison_name => 'a_b'
  );
END;
/
BEGIN
  DBMS_COMPARISON.CREATE_COMPARISON(
    comparison_name    => 'a_b',
    schema_name        => user,
    object_name        => 'A',
    remote_object_name => 'B',
    dblink_name        => null);
END;
/
 
SET SERVEROUTPUT ON
DECLARE
  consistent   BOOLEAN;
  scan_info    DBMS_COMPARISON.COMPARISON_TYPE;
BEGIN
  consistent := DBMS_COMPARISON.COMPARE(
    comparison_name => 'a_b',
    scan_info       => scan_info,
    perform_row_dif => TRUE
  );
  DBMS_OUTPUT.PUT_LINE('Scan ID: '||scan_info.scan_id);
  IF consistent=TRUE THEN
    DBMS_OUTPUT.PUT_LINE('No differences were found.');
  ELSE
    DBMS_OUTPUT.PUT_LINE('Differences were found.');
  END IF;
END;
/



