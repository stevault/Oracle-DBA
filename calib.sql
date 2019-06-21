Set serveroutput on size 1000000
Declare
Calc_lat number;
Calc_iops number;
Calc_mbps number;
Begin
Dbms_resource_manager.calibrate_io(&dsks,&maxlat, Calc_iops, Calc_mbps, Calc_lat);
Dbms_output.put_line('Max IOPS : '||Calc_iops);
Dbms_output.put_line('Max mbytes-per-sec: '||Calc_mbps);
Dbms_output.put_line('Calc. latency : '||Calc_lat);
End;
/

