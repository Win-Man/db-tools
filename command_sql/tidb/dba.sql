## 系统表查询语句
### 查询慢日志中扫描 key 最多的语句

```sql
select digest, avg(query_time), avg(cop_proc_avg), max(cop_proc_avg), min(cop_proc_avg), max(query_time), min(query_time), count(*), max(process_keys), min(process_keys) from slow_query group by digest order by max(process_keys) desc limit 10;
```

### 查询SQL语句、类型、使用索引情况以及执行计划信息

```sql
SELECT STMT_TYPE,SCHEMA_NAME,DIGEST,DIGEST_TEXT,QUERY_SAMPLE_TEXT,TABLE_NAMES,INDEX_NAMES,SAMPLE_USER,PLAN_DIGEST,PLAN FROM performance_schema.events_statements_summary_by_digest\G
```

### 找出某一时间段内耗时前三的 SQL

```sql
SELECT sum_latency, avg_latency, exec_count, query_sample_text
    FROM performance_schema.events_statements_summary_by_digest_history
    WHERE summary_begin_time = '2020-01-02 10:00:00' 
    ORDER BY sum_latency DESC LIMIT 3;
```

### 查询 mvcc 版本过多的前三 SQL

```sql
SELECT STMT_TYPE,DIGEST_TEXT,EXEC_COUNT,AVG_PROCESSED_KEYS,AVG_TOTAL_KEYS,(1 - AVG_PROCESSED_KEYS/AVG_TOTAL_KEYS) AS per from events_statements_summary_by_digest_history WHERE AVG_PROCESSED_KEYS != 0  order by (1 - AVG_PROCESSED_KEYS/AVG_TOTAL_KEYS) desc limit 3\G
```

### 查询写入量最大的前三 SQL

```sql
SELECT STMT_TYPE,DIGEST_TEXT,EXEC_COUNT,AVG_WRITE_KEYS,AVG_WRITE_SIZE,(AVG_WRITE_SIZE/AVG_WRITE_SIZE/AVG_WRITE_KEYS) from events_statements_summary_by_digest_history order by AVG_WRITE_SIZE desc limit 3\G
```

### 判断 SQL 慢是客户端慢还是服务端慢，查看服务端对应 SQL 的时间

```sql
select avg_latency, query_sample_text from events_statements_summary_by_digest where QUERY_SAMPLE_TEXT LIKE 'select buyer_id, item_id from `order`%'\G
```

### 查询各个组件的地址和版本信息

```sql
 select * from INFORMATION_SCHEMA.CLUSTER_INFO;
```

### 查询各个组件配置

```sql
select * from information_schema.`CLUSTER_CONFIG` where type=’tikv’ and `key` like ‘%max-sub%’;
```

### 查看配置值不一样的配置项

```sql
select count(distinct value) , `key` from information_schema.cluster_config group by `key` having count(distinct value) >1;
```

### 查看节点硬件信息

```sql
select * from information_schema.`CLUSTER_HARDWARE` where device_type=”cpu” and name in (“cpu-physical-cores”,”cpu-logical-cores”);

select * from information_schema.`CLUSTER_HARDWARE` where device_type=’disk’ and type =’tikv’ and name like ‘%used-percent%’
```

### 查看节点 sysctl -a 系统配置信息

```sql
select * from information_schema.`CLUSTER_SYSTEMINFO` where name like ‘%tcp_keepalive_time%’;
```

### 查看节点内存使用字节数

```sql
 select * from information_schema.`CLUSTER_LOAD` where device_type=’memory’ and name=’used’ and value !=0;
```

### 某个表一共有多少region，在每个tikv/tiflash上分别多少

```sql
select r.table_name, r.db_name, r.store_id, s.address, r.is_leader, count(*) as cnt from (
    select s.region_id, s.table_name, s.db_name, s.is_index, p.store_id, p.is_leader, p.status
    from tikv_region_status s,tikv_region_peers p
    where db_name ='tpch_1' and table_name='lineitem' and s.region_id = p.region_id
) as r, tikv_store_status s
where r.store_id=s.store_id
group by r.store_id, r.is_leader, s.address;
```

### 查看每个表的 region 数

```sql
select count(*),max(db_name),max(table_name) from information_schema.tikv_region_status where db_name='test' and table_name='t';
```

### 查看每个表的 region 分布情况

```sql
SELECT b.store_id,count(b.region_id) FROM tikv_region_status a  join TIKV_REGION_PEERS b on a.REGION_ID=b.REGION_ID  where a.db_name='test' and a.table_name='t1' and b.is_leader=1  and a.IS_INDEX=0 group by b.store_id;
```

### 查 peer 多或者少的时候，store-id 和 count region id 的对应关系，如果不正常 peer 都集中在某个 store，那就需要看下这个 store 是不是异常的

```sql
select store_id,count(distinct rs.region_id) from TIKV_REGION_peers rs join (select REGION_ID,count(distinct PEER_ID) from TIKV_REGION_PEERS group by REGION_ID having count(distinct PEER_ID)>3) s on rs.REGION_ID= s.region_id group by rs.store_id order by 2 desc ;
```

### 有 extra peer 或者其他 peer 多或者少 的情况，可以用这个查一下涉及到哪个库哪个表，如果 基本上都包含了，那大概率是集群的问题，如果集中在某个表，可能是表的问题，缩小范围

```sql
select rs.db_name,rs.table_name,rs.index_name,count(distinct rs.region_id) from TIKV_REGION_STATUS rs join (select REGION_ID,count(distinct PEER_ID) from TIKV_REGION_PEERS group by REGION_ID having count(distinct PEER_ID)>3) s on rs.REGION_ID= s.region_id group by rs.db_name,rs.table_name,rs.index_name;
```

### 查找当前在等待锁的语句情况

```sql
use information_schema;
select cssh.schema_name,d.*,c.instance,c.start_time,TIMESTAMPDIFF(SECOND,c.start_time,CURTIME()) as run_time,c.waiting_start_time,TIMESTAMPDIFF(SECOND,c.waiting_start_time,CURTIME()) as waiting_time,c.session_id,c.user,c.db,cssh.DIGEST_TEXT from data_lock_waits d left join cluster_tidb_trx c on  d.TRX_ID=c.id left join cluster_statements_summary cssh on d.sql_digest = cssh.digest and c.db = cssh.schema_name and cssh.SUMMARY_END_TIME >= c.start_time and cssh.SUMMARY_BEGIN_TIME <= c.start_time\G
```

### 查看当前导致锁等待的语句，但是如果事务是执行了，但是没提交的状态， current_sql_digest  为 null ，需要人为通过 all digest 去手动查

```sql
use information_schema;
select * from cluster_tidb_trx where id = 426177787423883265;
```

### 判断当前数据库是否发生死锁问题，并找出阻塞和被阻塞的 sql 

```sql
 select l.deadlock_id, l.occur_time, l.try_lock_trx_id, l.trx_holding_lock, s.digest_text from information_schema.deadlocks as l left join information_schema.statements_summary as s on l.current_sql_digest = s.digest; 
```