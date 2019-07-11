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

kldload $SLS_DIR/kmod/sls.ko > /dev/null 2>&1

cpuset -l 0-23 ./$COMMAND $@  &

cp $SLS_DIR/tools/slsctl/slsctl .
SLS=./slsctl

$SLS > /dev/null;

# This removes space 
PID=`pidof $COMMAND | xargs`

if ! [[ -z "$FREQ" ]]
then
	$(dtrace -s $SLS_DIR/trace/sls-trace.d -o trace.log $PID) &
	$SLS ckptstart -p $PID -t $FREQ -f $MOUNT_DIR/$PID.sls
	if [ $? -ne 0 ]
	then
		echo "ERROR IN SLS CALL"
		exit 1
	fi
fi

wait $PID
pkill dtrace
rm $MOUNT_DIR/$PID.sls

