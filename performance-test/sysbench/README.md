## oltp_common.lua 修改内容
1. prepare 造数时，将 CREATE INDEX 操作提前到插入数据之前，这是为了测试 TiDB 时，加快造数过程。

```
oltp_common.lua 的第 235 行到第 240 行移动到第 198 行以后
```

2. 添加 mysql_table_options 选项，方便传入一些额外的参数

![](https://raw.githubusercontent.com/Win-Man/pic-storage/master/img/mysql_table_options1.png)

![](https://raw.githubusercontent.com/Win-Man/pic-storage/master/img/mysql_table_options2.png)

3. 添加 auto_random 支持 TiDB AUTO_RANDOM 

![](https://raw.githubusercontent.com/Win-Man/pic-storage/master/img/20200411152244.png)

![](https://raw.githubusercontent.com/Win-Man/pic-storage/master/img/20200411152317.png)

## auto_sysbench.sh 使用

```
$ sh auto_sysbench.sh
```

## run_sysbench.sh 使用

```
$ sh run_sysbench.sh oltp_read_write 32
```