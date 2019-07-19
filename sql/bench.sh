FREQ=1000
SQDIR=/usr/home/ryan/workspace/mysql
SLS=/usr/home/ryan/workspace/sls/tools/slsctl/slsctl
export LD_PRELOAD=$SQDIR/build/lib/libmysqlclient.so.21
./sysbench/sysbench --test=oltp --mysql-table-engine=memory --oltp-table-size=10000 --mysql-user=root --mysql-password=dingdong --mysql-port=33060 prepare

$SLS ckptstart -p 94217 -t $FREQ -d -o
./sysbench/sysbench --num-threads=8 --max-requests=3000 --test=oltp --oltp-table-size=10000 --mysql-user=root --mysql-password=dingdong --mysql-port=33060 run 
$SLS chptstop -p 94217 



