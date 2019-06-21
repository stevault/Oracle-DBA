

delete from sysaud where ntimestamp# >= trunc(sysdate);

insert into sysaud select * from sys.aud$ where ntimestamp# >= trunc(sysdate);

truncate table sys.aud$ ;

insert into sys.aud$ select * from sysaud;

drop table sysaud;

alter table sys.aud$ move tablespace sysaud;




