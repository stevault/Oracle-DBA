select a.segment_name, max(a.mb) big_ext , b.bytes/1024/1024 mb
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
where a.mb > 4000
and a.segment_name = b.segment_name
and a.owner = b.owner
group by a.segment_name, b.bytes
/

