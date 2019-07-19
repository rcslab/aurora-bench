#!/usr/local/bin/bash


BIN=$1
SLS_DIR=$2
FREQ=$3

if [ -z "$1" ]
then
	echo "run.sh SQL_BIN_DIR  SLS_DIR FREQ"
	exit 1
fi

if [ -z "$2" ]
then
	echo "run.sh SQL_BIN_DIR  SLS_DIR FREQ"
	exit 1
fi

export LD_PRELOAD=./libmysqlclient.so.21

SYSBENCH=./sysb
SLS=$SLS_DIR/tools/slsctl/slsctl

$SYSBENCH --version;
if [ $? -ne 0 ]
then
	exit 1
fi

$SLS;
if [ $? -ne 0 ]
then
	exit 1
fi

KMOD=$SLS_DIR/kmod/sls.ko
kldload $KMOD

DATA_DIR=`pwd`/.tmp_SQL
LOG=TMP
SQLD=$BIN/mysqld
ADMIN=$BIN/mysqladmin

mkdir $DATA_DIR
$SQLD --initialize-insecure  \
	--datadir=$DATA_DIR
chown -R ryan $DATA_DIR
$SQLD --user=ryan --bind-address=127.0.0.1 \
	--datadir=$DATA_DIR  &


sleep 8
PID=`pidof mysqld`
echo $PID

echo "Creating password - db1234 for database"
python3 setup.py pre

$SYSBENCH --test=oltp --mysql-table-engine=memory --oltp-table-size=10000 --mysql-user=root --mysql-password=db1234 --mysql-port=33060 prepare
if [ -z "$3" ]
then
echo "Checkpointing started of $PID"
$SLS chkptstart -p $PID -t $3 -f $PID.sls
fi

$SYSBENCH --num-threads=8 --max-requests=3000 --test=oltp --oltp-table-size=10000 --mysql-user=root --mysql-password=db1234 --mysql-port=33060 run 

if [-z "$3" ]
then
echo "Checkpointing stopped of $PID"
$SLS chkptstop -p $PID
fi

echo "Killing daemon and unloading kernal module"
pkill mysqld
rm -rf $DATA_DIR
kldunload sls.ko

