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

$SLS_DIR/tools/newosd/newosd /dev/vtbd1
kldload $SLS_DIR/slos/slos.ko > /dev/null 2>&1
kldload $SLS_DIR/kmod/sls.ko > /dev/null 2>&1

echo "$COMMAND $@"

#CPU=`sysctl -a | grep 'hw.ncpu' | cut -f -2 -d ':'`
#CPU=`expr $CPU - 1`
$(dtrace -s $SLS_DIR/trace/sls-trace.d -o trace.log) &

cpuset -l 0-7 ./$COMMAND $@  &
PID=`pidof $COMMAND | xargs`

wait $PID
rm slsctl
pkill dtrace

kldunload sls.ko

ERR=$?

while [ $ERR -ne 0 ]
do
    sleep 2
    kldunload sls.ko
    ERR=$?
done

kldunload slos.ko

exit 0

