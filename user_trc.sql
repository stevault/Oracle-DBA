define USER_ID=&1

CREATE OR REPLACE TRIGGER USER_TRACE_TRG
AFTER LOGON ON DATABASE
BEGIN
    IF USER = '&USER_ID'
  THEN
    execute immediate 'alter session set events ''10046 trace name context forever, level 12''';
  END IF;
EXCEPTION
WHEN OTHERS THEN
NULL;
END;
/

