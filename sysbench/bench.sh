CURRENT=$(pwd)
cd ..
SQDIR=$(pwd)
cd $CURRENT
export LD_PRELOAD=$SQDIR/build/lib/libmysqlclient.so.21
./sysbench/sysbench --test=oltp --mysql-table-engine=memory --oltp-table-size=10000 --mysql-user=root --mysql-password=dingdong --mysql-port=33060 prepare
./sysbench/sysbench --num-threads=8 --max-requests=3000 --test=oltp --oltp-table-size=10000 --mysql-user=root --mysql-password=dingdong --mysql-port=33060 run 
