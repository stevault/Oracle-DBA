whenever sqlerror exit sql.sqlcode

set timing on
col seg_mb format 9999999
col max_ext_loc format 9999999

spool dm1.log

select to_char(sysdate,'HH24:MI:SS') curtime from dual;

prompt SHOW SEGMENTS
select a.segment_name, max(a.mb) max_ext_loc, b.bytes/1024/1024 seg_mb
from (
select owner, segment_name, block_id
        , block_id+blocks
        , blocks, bytes, bytes/blocks
        , ((bytes/blocks) * (block_id+blocks) )/1024/1024 mb
 from dba_extents
 where tablespace_name = 'DATAMART_DATA'
--and block_id in (select max(block_id) from dba_extents where tablespace_name = 'DATAMART_DATA')
order by block_id desc
) a,
dba_segments b
where a.mb > 1000
and a.segment_name = b.segment_name
and a.owner = 'DW_ST'
and a.owner = b.owner
group by a.segment_name, b.bytes
order by a.segment_name, b.bytes
/


prompt SHOW INVALID INDEXES
select index_name, table_name, owner, status
from dba_indexes
where status not in ('VALID','N/A')
order by table_name, index_name
/


set echo on

alter table dw_st.DRAGON_POLICY move;
alter index dw_st.DRAGON_POLICY_AK1 rebuild;
alter index dw_st.DRAGON_POLICY_AK2 rebuild;
alter index dw_st.DRAGON_POLICY_AK3 rebuild;
alter index dw_st.DRAGON_POLICY_I1 rebuild;
alter index dw_st.DRAGON_POLICY_I4 rebuild;
alter index dw_st.DRAGON_POLICY_PK rebuild;
alter index dw_st.TRX_POLICY_STA_LOB rebuild;
alter index dw_st.TRX_POLICY_STA_LOB_2 rebuild;
alter table dw_st.DRAGON_QUOTE move;
alter index dw_st.DRAGON_QUOTE_PK rebuild;
alter table dw_st.DRAGON_SESSION move;
alter index dw_st.DRAGON_SESSION_AK rebuild;
alter index dw_st.DRAGON_SESSION_PK rebuild;
alter table dw_st.DRAGON_SUBMISSION move;
alter index dw_st.DRAGON_SUBMISSION_CIDX rebuild;
alter index dw_st.DRAGON_SUBMISSION_I1 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I10 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I11 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I13 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I2 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I3 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I4 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I5 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I6 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I7 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I8 rebuild;
alter index dw_st.DRAGON_SUBMISSION_I9 rebuild;
alter index dw_st.DRAGON_SUBMISSION_PK rebuild;
alter index dw_st.DRAGON_SUBMISSION_SUBMISSION_1 rebuild;
alter table dw_st.DRAGON_TASK move;
alter index dw_st.DRAGON_TASK_I1 rebuild;
alter index dw_st.DRAGON_TASK_PK rebuild;
alter table dw_st.DRAGON_USER move;
alter index dw_st.DRAGON_USER_GROUP_AK rebuild;
alter index dw_st.DRAGON_USER_I1 rebuild;
alter index dw_st.DRAGON_USER_I2 rebuild;
alter index dw_st.DRAGON_USER_NAME_AK rebuild;
alter index dw_st.DRAGON_USER_PK rebuild;
alter index dw_st.IDX_USER_ID rebuild;

set echo off

prompt SHOW INVALID INDEXES
select index_name, table_name, owner, status
from dba_indexes
where status not in ('VALID','N/A')
order by table_name, index_name
/

prompt SHOW BIG SEGMENTS
select a.segment_name, max(a.mb) max_ext_loc, b.bytes/1024/1024 seg_mb
from (
select owner, segment_name, block_id
        , block_id+blocks
        , blocks, bytes, bytes/blocks
        , ((bytes/blocks) * (block_id+blocks) )/1024/1024 mb
 from dba_extents
 where tablespace_name = 'DATAMART_DATA'
--and block_id in (select max(block_id) from dba_extents where tablespace_name = 'DATAMART_DATA')
order by block_id desc
) a,
dba_segments b
where a.mb > 1000
and a.segment_name = b.segment_name
and a.owner = 'DW_ST'
and a.owner = b.owner
group by a.segment_name, b.bytes
order by a.segment_name, b.bytes
/

select to_char(sysdate,'HH24:MI:SS') curtime from dual;


