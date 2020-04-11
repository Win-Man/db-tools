#!/bin/bash
TYPE=$1
THREADS=$2
CNF_PATH=./config
LOG_PATH=./sysbench_log
TABLES=32
TABLE_SIZE=10000000

mkdir -p ${LOG_PATH}

main(){
    local FILE_PATH="${LOG_PATH}/sysbench-${TYPE}-${THREADS}_`date +%Y%m%d_%H%M%S`.log"
    echo "START TIME:`date '+%Y-%m-%d %H:%M:%S'`" | tee -a ${FILE_PATH}
    echo "Config Content:" | tee -a ${FILE_PATH}
    cat ${CNF_PATH} | tee -a ${FILE_PATH}
    echo "Command:" | tee -a ${FILE_PATH}
    echo "sysbench --config-file=${CNF_PATH} ${TYPE} --threads=${THREADS} --tables=${TABLES} --table-size=${TABLE_SIZE} run" | tee -a ${FILE_PATH}
    sysbench --config-file=${CNF_PATH} ${TYPE} --threads=${THREADS} --tables=${TABLES} --table-size=${TABLE_SIZE} run | tee -a ${FILE_PATH} 2>&1
    echo "END TIME:`date '+%Y-%m-%d %H:%M:%S'`" | tee -a ${FILE_PATH}
}

main