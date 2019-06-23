
create profile awdba limit failed_login_attempts unlimited;

create user awdba identified by awdba profile awdba;

grant dba,sysdba to awdba;


