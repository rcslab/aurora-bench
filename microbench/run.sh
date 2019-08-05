#!/usr/local/bin/bash

COMMAND=$1
SLS_DIR=$2
MOUNT_DIR=$3
FREQ=$4
shift
shift
shift
shift


rm trace.log > /dev/null 2>&1

kldload $SLS_DIR/slos/slos.ko > /dev/null 2>&1
kldload $SLS_DIR/kmod/sls.ko > /dev/null 2>&1

echo "$COMMAND $@"

CPU=`sysctl -a | egrep -i 'hw.ncpu' | cut -f -2 -d ':' | xargs`
CPU=`expr $CPU - 1`
cpuset -l 0-$CPU ./$COMMAND $@  &

cp $SLS_DIR/tools/slsctl/slsctl .
SLS=./slsctl

$SLS > /dev/null;

# This removes space 
PID=`pidof $COMMAND | xargs`

if ! [[ -z "$FREQ" ]]
then
	$(dtrace -s $SLS_DIR/trace/sls-trace.d -o trace.log) &
	$SLS attach -p $PID -t $FREQ -o $PID
	if [ $? -ne 0 ]
	then
		echo "ERROR IN SLS CALL"
		exit 1
	fi
fi

wait $PID
pkill dtrace

