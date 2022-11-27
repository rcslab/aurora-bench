#!/bin/sh
. aurora.config
. helpers/util.sh

# Don't allow unset variables
set -u

AURORACTL=$SRCROOT/tools/slsctl/slsctl
AURORA_DSMB_DIR="/tmp/dsmb"

PPD_BIN=$(pwd)/dependencies/dsmb/build/ppd
PPD_THREADS=12
PPD_PORT=`jot -r 1 10000 14000`
PPD_AFFINITY="0,2,4,6,8,10,12,14,16,18,20,22"
PPD_MODE="3"
PPD_URL=$MC_URL

DSMB_BIN="$AURORA_CLIENT_DIR/dsmb/build/dismember"
DSMB_THREADS=12
DSMB_MASTER_THREADS=12
DSMB_WARMUP=5
DSMB_TIME=15
DSMB_AFFINITY="0,2,4,6,8,10,12,14,16,18,20,22"
DSMB_WORKLOAD="2"
DSMB_MASTER_QPS="1000"
DSMB_CLIENT_THREADS="12"
DSMB_CLIENT_CONNS="12"

SLEEPTIME=30
DISKPATH=""

DSMB_AGENTS="$EXTERNAL_HOSTS"
DSMB_MASTER="$MUT_MASTER"
DSMB_ALL_HOSTS="$DSMB_AGENTS $DSMB_MASTER"

start_clients()
{
    echo "In start_clients"
    CLIENT_COMMAND="$DSMB_BIN -l $DSMB_WORKLOAD -c $DSMB_CLIENT_CONNS -t $DSMB_CLIENT_THREADS  -A"

    set -- $DSMB_AGENTS
    while [ -n "${1+set}" ];
    do
	DSMB_CLIENT=$1
	echo "[Aurora] Starting DSMB Agent at $DSMB_CLIENT"

    	echo "Executing client command: $CLIENT_COMMAND"
	echo "Accessing client $DSMB_CLIENT"

	ssh $DSMB_CLIENT "cpuset -l $DSMB_AFFINITY $CLIENT_COMMAND" &
	shift
    done
}

start_master()
{
    echo "In start_master"

    # Construct the hosts array.
   HOSTS=""
    set -- $DSMB_AGENTS
    while [ -n "${1+set}" ];
    do
	HOSTS="-a $1 ${HOSTS}"
	shift
    done

    DSMB_MASTER_CMD="$DSMB_BIN \
	-T $DSMB_MASTER_THREADS \
	-Q $DSMB_MASTER_QPS \
	-s $PPD_URL \
	-p $PPD_PORT \
	-W $DSMB_WARMUP \
	-w $DSMB_TIME \
	-l $DSMB_WORKLOAD \
	-c $DSMB_CLIENT_CONNS \
	-o /tmp/out \
	$HOSTS"

    echo "[Aurora]  Executing command: $DSMB_MASTER_CMD"

    ssh "$DSMB_MASTER" "cpuset -l $DSMB_AFFINITY $DSMB_MASTER_CMD" 
    scp "$DSMB_MASTER:/tmp/out" /tmp/out

    return $!
}

stop_dsmb()
{
    echo "In stop_dsmb"
    set -- $DSMB_ALL_HOSTS
    while [ -n "${1+set}" ];
    do
	HOST="$1"
	echo "[Aurora] Killing dismember agents at $HOST"
	ssh $HOST "kill -TERM \`pidof dismember\` >/dev/null 2>/dev/null" 
	shift
    done
}

# Invoke the ping pong daemon.
invoke_ppd()
{
    echo "In invoke_ppd"

    PPD_COMMAND="$PPD_BIN -p $PPD_PORT -m -t $PPD_THREADS -M $PPD_MODE"

    echo "Executing $PPD_COMMAND"
    cpuset -l $PPD_AFFINITY $PPD_COMMAND &
}

run_ppd()
{
    echo "In run_ppd"

    # Check if we're running with SLS on.
    CHILD_DIR=$1
    ITER=$2
    if [ "$#" -gt 2 ]; then
	echo 1
	FREQ=$3
	SLS="on"
	teardown_aurora  
	echo 2
    else
	SLS="off"
    fi

    pkill ppd
    stop_dsmb

    CHILD_DIR=$1
    ITER=$2

    # Stop all previous PPD servers.
    kill -KILL `pidof ppd` >/dev/null 2>/dev/null
    stop_dsmb

    # Start the mutilate agents.
    start_clients

    # Invoke the memcached server command.
    invoke_ppd
    sleep 1

    # Start checkpointing if the SLS is on.
    PID=`pidof ppd`
    if [ "$SLS" = "on" ]; then
	echo "[Aurora] Attaching memcached Server to Aurora: $PID"
	setup_aurora $FREQ >> $LOG 2>> $LOG
	$AURORACTL partadd $BACKEND -o 1 -d -t $FREQ >> $LOG 2>> $LOG
	$AURORACTL attach -o 1 -p $PID >> $LOG 2>> $LOG
	$AURORACTL checkpoint -o 1 -r >> $LOG 2>> $LOG
    fi
    echo "[Aurora] PPD server at: $PID"

    # Wait for the mutilate master to finish up.
    start_master

    # XXX Find a way to actually wait for the ssh session to end, this doesn't work for some reason.
    sleep $SLEEPTIME

    # Kill the local server and possibly teardown Aurora.
    kill -KILL `pidof ppd` 2>&1 >/dev/null


    if [ $? -eq 124 ]; then
	echo "[Aurora] PPD timed out, restarting."
	exit 1
    fi

    # Stop dismember clients.
    pkill ppd
    stop_dsmb
    teardown_aurora  >> $LOG 2>> $LOG

    cat /tmp/out
    mv /tmp/out $OUT/ppd/$CHILD_DIR/$ITER.out
    fsync $OUT/ppd/$CHILD_DIR/$ITER.out
    # Wait for port to become available again
    
    echo "[Aurora] Done"
    return 0
}

run_base()
{
    mkdir -p $OUT/ppd/base 2> /dev/null

    ARR=`seq 1 $MAX_ITER`
    set -- $ARR
    while [ -n "${1+set}" ];
    do
	ITER=$1
	echo "[Aurora] Attempting base: $ITER"
	# Check if we have already computed the result.
	if check_completed $OUT/ppd/base/$ITER.out; then
	    shift
	    continue
	fi

	echo "[Aurora] Running memcached base: $ITER"
	run_ppd "base" $ITER 2>&1 | tee $LOG 
	if [ "$?" -eq 0 ];then
		shift
	fi

	sleep 10
    done
    echo "[Aurora] Done running memcached base"

}

run_aurora()
{
    for PERIOD in `seq $MIN_FREQ $FREQ_STEP $MAX_FREQ`
    do
	mkdir -p $OUT/ppd/$PERIOD 2> /dev/null
	ARR=`seq 1 $MAX_ITER`
	set -- $ARR
	while [ -n "${1+set}" ];
	do
	    ITER=$1
	    if check_completed $OUT/ppd/$PERIOD/$ITER.out; then
		shift
		continue
	    fi
	    echo "[Aurora] Running memcached with Aurora: Checkpoint period $PERIOD, Iteration $ITER"
	    run_ppd "$PERIOD" $ITER $PERIOD 2>&1 | tee $LOG 
	    if [ "$?" -eq 0 ];then
		shift
	    fi
	    sleep 10
	done
    done
    echo "[Aurora] Done running memcached with Aurora"
}


check_mutilate_install()
{
    set -- $DSMB_ALL_HOSTS
    while [ -n "${1+set}" ];
    do
	HOST=$1
	echo "Accessing all hosts: $HOST"
	ssh $HOST "$DSMB_BIN -h" > /dev/null 2> /dev/null
	if [ $? != 0 ];then
		echo "[Aurora] DSMB agent not installed on host($HOST) - please re-run setup.sh"
		exit 1
	fi
	shift
    done

}

setup_script

check_mutilate_install

clear_log

if [ "$MODE" = "VM" ]; then
	MAX_ITER=1
else
	MAX_ITER=2
fi
echo "[Aurora] Running with $MAX_ITER iterations"

run_base

run_aurora 

#PYTHONPATH=${PYTHONPATH+""}:$(pwd)/dependencies/progbg
#export PYTHONPATH
#export OUT
#export MODE
#echo "[Aurora] Creating Fig4b Graph"
#python3.7 -m progbg graphing/fig4b.py
#
