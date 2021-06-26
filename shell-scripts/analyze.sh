#!/bin/bash
HOST=127.0.0.1
USER=root
PASSWORD=
PORT=4000

for i in $(mysql -u${USER} -P${PORT} -h${HOST} -e "show stats_healthy where db_name='gangshen'" | egrep -v '100|Table_name' | awk '{print $2}' | xargs)
do
    mysql -u${USER} -P${PORT} -h${HOST} -e "analyze table gangshen.${i}"
    echo "analyze table gangshen.${i} done."
done
