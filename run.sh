#!/usr/local/bin/bash

SLS_DIR=$1
FREQ=$2

if ! [[ -z "$FREQ" ]]
then
	echo "Running with SLS - Freq set at $FREQ"
fi
kldload $SLS_DIR/kmod/sls.ko

cpuset -l 0-7 checks/a.out  &

cp $SLS_DIR/tools/slsctl/slsctl .
SLS=./slsctl

$SLS;

# This removes space 
PID=`pidof a.out | xargs`
echo $PID

if ! [[ -z "$FREQ" ]]
then
	echo "Checkpointing started of $PID"
	echo "$SLS ckptstart -p $PID -t $FREQ -f /$PID.sls"
	#$(dtrace -s sls-trace.d -p $PID -o /slsbench/trace.log $PID) &
	$SLS ckptstart -p $PID -t $FREQ -f $PID.sls
	if [ $? -ne 0 ]
	then
		echo "ERROR IN SLS CALL"
	fi
fi
