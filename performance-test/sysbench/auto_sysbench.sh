#/bin/bash
TH=(8 16 32 64 128 256 512)
TYPE=(
oltp_read_only
oltp_point_select
oltp_update_index
oltp_read_write
oltp_write_only
)
INTERVAL=60
PREPARE=1

SHARD_ID=1

if [ ${PREPARE} -eq 1 ];then
    if [ ${SHARD_ID} -eq 1 ];then
        sysbench --config-file=./config oltp_point_select  --tables=32 --table-size=10000000 --threads=16 --secondary=on  --create-secondary=off --auto_inc=off --mysql_table_options='shard_row_id_bits=10 pre_split_regions=10' prepare
    else
        sysbench --config-file=./config oltp_point_select --tables=32 --table-size=10000000 --threads=16 prepare
    fi
fi


for t in ${TYPE[@]};
do
    for i in ${TH[@]};
    do
        date
        echo "START RUN ${t}-${i} TEST"
        sh ./run_sysbench.sh ${t} ${i}
        echo "SELEEP ${INTERVAL} seconds......"
        sleep ${INTERVAL}
    done
done