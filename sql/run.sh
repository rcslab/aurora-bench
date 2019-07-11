#!/usr/local/bin/bash

BIN=$1/bin
SLS_DIR=$2
FREQ=$3

if [ -z "$1" ]
then
	echo "run.sh SQL_BIN_DIR SLS_DIR FREQ"
	exit 1
fi

if [ -z "$2" ]
then
	echo "run.sh SQL_BIN_DIR SLS_DIR FREQ"
	exit 1
fi

if ! [[ -z "$FREQ" ]]
then
	echo "Running with SLS - Freq set at $FREQ"
fi

export LD_PRELOAD=$1/lib/libmysqlclient.so.21

SYSBENCH=/usr/local/bin/sysbench
cp $SLS_DIR/tools/slsctl/slsctl .
SLS=./slsctl

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
# This removes space 
PID=`pidof mysqld | xargs`
echo $PID

echo "Creating password - db1234 for database"
python3 setup.py pre

$SYSBENCH --mysql-user=root --mysql-password=db1234 --mysql-socket=/tmp/mysql.sock oltp_read_write --mysql-storage-engine=memory prepare
if ! [[ -z "$FREQ" ]]
then
	echo "Checkpointing started of $PID"
	echo "$SLS ckptstart -p $PID -t $FREQ -f /$PID.sls"
	$(dtrace -s ../sls-trace.d -p $PID -o trace.log $PID) &
	$SLS ckptstart -p $PID -t $FREQ -f $PID.sls
	if [ $? -ne 0 ]
	then
		echo "ERROR IN SLS CALL"
	fi
fi

#$(truss -D -H -o ./truss.log -p $PID) &
$SYSBENCH --threads=8 --mysql-user=root --mysql-password=db1234 --mysql-socket=/tmp/mysql.sock oltp_read_write run 

if ! [[ -z "$FREQ" ]]
then
echo "Checkpointing stopped of $PID"
echo "$SLS ckptstop -p $PID"
$SLS ckptstop -p $PID
fi

sleep 5
echo "Killing daemon and unloading kernal module"
pkill mysqld
sleep 10
rm -rf $DATA_DIR
rm slsctl
kldunload sls.ko
rm /$PID.sls

