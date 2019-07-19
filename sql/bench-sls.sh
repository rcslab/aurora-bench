SQDIR=/usr/home/ryan/workspace/mysql
export LD_PRELOAD=$SQDIR/build/lib/libmysqlclient.so.21
./slsctl ckptstart -p 9914 -t 1000 -f 9914.sls
./sysbench/sysbench --test=oltp --mysql-table-engine=memory --oltp-table-size=10000 --mysql-user=root --mysql-password=dingdong --mysql-port=33060 prepare
./sysbench/sysbench --num-threads=8 --max-requests=3000 --test=oltp --oltp-table-size=10000 --mysql-user=root --mysql-password=dingdong --mysql-port=33060 run 
./slsctl ckptstop -p 9914 



