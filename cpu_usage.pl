my $agent_pid_str=`/u01/app/oracle/product/agent12c/agent_inst/bin/emctl status agent | grep "Agent Process"`;

my @tmp = split(':',$agent_pid_str); 
chomp $tmp[1];

my $agent_pid = $tmp[1]; 

#Find the agent cpu utilization using ps
my $cmd = "ps -p $agent_pid -o pcpu";
my @ps_cpu_util_arr=`ps -p $agent_pid -o pcpu`;
chomp $ps_cpu_util_arr[1];
my $ps_cpu_util = $ps_cpu_util_arr[1];
print "em_result=$agent_pid|$ps_cpu_util\n";

