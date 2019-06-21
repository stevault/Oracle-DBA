alter system set CURSOR_SHARING = FORCE  scope=spfile;
--
alter system set MEMORY_MAX_TARGET = 12G scope=spfile;
alter system set MEMORY_TARGET = 12G scope=spfile;
--
alter system set PGA_AGGREGATE_TARGET = 2489M	 scope=spfile;
--
alter system set SGA_MAX_SIZE = 10G scope=spfile;
--alter system set SGA_TARGET 
--
alter system set SHARED_POOL_SIZE = 4G scope=spfile;
--
alter system set SESSION_CACHED_CURSORS = 50 scope=spfile;
--
alter system set OPEN_CURSORS = 3400 scope=spfile;
alter system set PROCESSES = 3000 scope=spfile;
--
--alter system set STREAMS_POOL_SIZE

