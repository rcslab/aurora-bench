#!/bin/sh
. aurora.config
. helpers/util.sh

# Don't allow unset variables
set -u

AURORACTL=$SRCROOT/tools/slsctl/slsctl
AURORA_MUT_DIR="/tmp/mutilate"

MC_THREADS=12
MC_PORT=`jot -r 1 10000 14000`
MC_PIDFILE="/tmp/memcached.pid"
MC_CONNECTIONS=98304
MC_AFFINITY="0,2,4,6,8,10,12,14,16,18,20,22"
MC_USER="root"
MC_BACKLOG="4096"

MUTILATE=$(pwd)/dependencies/mutilate/mutilate
MUT_THREADS=12
MUT_CONNECTIONS=12
MUT_WARMUP=10
MUT_TIME=15
MUT_AFFINITY="0,2,4,6,8,10,12,14,16,18,20,22"
MUT_PORT="5556"
MUT_QPS_LAT="1000"

MUT_ALL_HOSTS="$EXTERNAL_HOSTS $MUT_MASTER"

clean_mutilate()
{
	echo "In check_mutilate"
	HOST=$1
	echo "(1) Checking $HOST"
	CHECK=`ssh $HOST 'pidof mutilate'`
	if [ ! -z "$CHECK" ];then
		# We are being safe and killing and starting our own mutilate 
		# with arguments we want.
		echo "[Aurora] Old Mutilate found on $HOST - cleaning up"
		ssh $HOST "kill -TERM \`pidof mutilate\`" 
		SOCKSTAT=`ssh $HOST  "sockstat | grep $MUT_PORT"`
		while [ ! -z "$SOCKSTAT" ];
		do
			echo "[Aurora] Socket still open - waiting"
			echo $SOCKSTAT
			SOCKSTAT=`ssh $HOST 'sockstat | grep $MUT_PORT'`
			sleep 5
		done
	fi

}

start_clients()
{
    echo "In start_clients"
    CLIENT_COMMAND="cd $AURORA_MUT_DIR; ./mutilate -T 16 -A -v"

    set -- $EXTERNAL_HOSTS
    while [ -n "${1+set}" ];
    do
	MUT_CLIENT=$1
	echo "[Aurora] Starting Mutilate Agent at $MUT_CLIENT"
	clean_mutilate $MUT_CLIENT

    	echo "Executing client command: $CLIENT_COMMAND"
	echo "Accessing client $MUT_CLIENT"

	ssh $MUT_CLIENT $CLIENT_COMMAND &
	shift
    done
}

start_master()
{
    echo "In start_master"
    clean_mutilate $MUT_MASTER

    # Construct the hosts array.
    HOSTS=""
    set -- $EXTERNAL_HOSTS
    while [ -n "${1+set}" ];
    do
	HOSTS="-a $1 ${HOSTS}"
	shift
    done

    MASTER_COMMAND="cd $AURORA_MUT_DIR; ./mutilate \
	-B -T $MUT_THREADS \
	-c $MUT_CONNECTIONS \
	-w $MUT_WARMUP \
	-q 120000 \
	-Q $MUT_QPS_LAT \
	-t $MUT_TIME \
	-s $MC_URL:$MC_PORT --noload \
	$HOSTS" 

    echo "Executing command: $MASTER_COMMAND"
    echo "(2) Accessing master $MUT_MASTER"

    ssh "$MUT_MASTER" "$MASTER_COMMAND" > /tmp/out &

    return $!
}

stop_mutilate()
{
    echo "In stop_mutilate"
    set -- $MUT_ALL_HOSTS
    while [ -n "${1+set}" ];
    do
	HOST="$1"
	echo "[Aurora] Killing Mutilate Agents at $HOST"
	ssh $HOST "kill -TERM \`pidof mutilate\`" 
	shift
    done
}

# The memcached server command
invoke_memcached()
{
    echo "In invoke_memcached"
    # Construct the command line argument pairs
    ADDRESS="-l $MC_URL"
    THREADS="-t $MC_THREADS"
    PORT_A="-p $MC_PORT"
    PIDFILE="-P $MC_PIDFILE"
    CONNECTIONS="-c $MC_CONNECTIONS"
    BACKLOG="-b $MC_BACKLOG"

    MC_COMMAND="memcached -u $USER $ADDRESS $THREADS $PORT_A $PIDFILE $CONNECTIONS $BACKLOG"

    echo "Executing $MC_COMMAND"
    cpuset -l $MC_AFFINITY $MC_COMMAND &
}

run_memcached()
{
    echo "In run_memcached"
    # Memcached sockets linger after death, just use another one every time.
    MC_PORT=`jot -r 1 10000 14000`

    CHILD_DIR=$1
    ITER=$2
    if [ "$#" -gt 2 ]; then
	FREQ=$3
	SLS="on"
    else
	SLS="off"
    fi

    # Stop all previous mutilate clients and the memcached server.
    kill -KILL `pidof memcached`
    kill -KILL `pidof mutilate`
    stop_mutilate

    # Check whether the memcached port is still in use
    SOCKSTAT=`sockstat | grep $MC_PORT`
    while [ ! -z "$SOCKSTAT" ];
    do
	echo "[Aurora] Socket still open - waiting"
	SOCKSTAT=`sockstat | grep $MC_PORT`
	kill -KILL `pidof memcached`
	sleep 5
    done

    # Start the mutilate agents.
    start_clients

    # If using the SLS, create the Aurora partition.
    if [ "$SLS" = "on" ]; then
	setup_aurora $FREQ >> $LOG 2>> $LOG
	$AURORACTL partadd $BACKEND -o 1 -d -t $FREQ >> $LOG 2>> $LOG
    fi

    # Invoke the memcached server command.
    invoke_memcached
    sleep 1

    ADDRESS="$MC_URL"
    # Load the server with data using a local mutilate instance.
    echo "[Aurora] Loading data to memcached server at $ADDRESS:$MC_PORT"
    echo "[Aurora] Loading data to memcached server at $ADDRESS:$MC_PORT" >> $LOG 2>> $LOG
    $MUTILATE -s "$MC_URL:$MC_PORT" --loadonly

    # Start checkpointing if the SLS is on.
    if [ "$SLS" = "on" ]; then
	pid=`pidof memcached`
	echo "[Aurora] Attaching memcached Server to Aurora: $pid"
	$AURORACTL attach -o 1 -p $pid >> $LOG 2>> $LOG
	$AURORACTL checkpoint -o 1 -r >> $LOG 2>> $LOG
    else
	pid=`pidof memcached`
	echo "[Aurora] memcached Server at: $pid"
    fi

    echo "[Aurora] Checking for mutilate on $1"
    echo "[Aurora] Starting mutilate $1"

    # Wait for the mutilate master to finish up.
    PID=`start_master`

    # XXX Find a way to actually wait for the ssh session to end, this doesn't work for some reason.
    SLEEPTIME=`seq 1 30`
    set -- $SLEEPTIME
    while [ -n "${1+set}" ];
    do
	sleep 1
    	ERR=`grep "BEV_EVENT_ERROR" $LOG`
        if [ ! -z "$ERR" ];then
        	echo "[Aurora] Problem with mutilate - restart asked"
		pkill -KILL memcached
		stop_mutilate
		if [ "$SLS" = "on" ]; then
			teardown_aurora  >> $LOG 2>> $LOG
		fi
		return 1
	fi
	shift
    done

    # Kill the local server and possibly teardown Aurora.
    kill -KILL `pidof memcached`

    if [ "$SLS" = "on" ]; then
	teardown_aurora  >> $LOG 2>> $LOG
    fi

    if [ $? -eq 124 ]; then
	echo "[Aurora] Issue with memcached timing out - restart is required"
	exit 1
    fi

    # Stop mutilate clients.
    stop_mutilate

    echo "========================"
    cat /tmp/out
    echo "========================"
    mv /tmp/out $OUT/memcached/$CHILD_DIR/$ITER.out
    fsync $OUT/memcached/$CHILD_DIR/$ITER.out
    # Wait for port to become available again
    
    echo "[Aurora] Done"
    return 0
}

run_base()
{
    mkdir -p $OUT/memcached/base 2> /dev/null

    ARR=`seq 1 $MAX_ITER`
    set -- $ARR
    echo "Array is $ARR"
    while [ -n "${1+set}" ];
    do
	ITER=$1
	echo "[Aurora] Attempting base: $ITER"
	# Check if we have already computed the result.
	if check_completed $OUT/memcached/base/$ITER.out; then
	    shift
	    continue
	fi

	echo "[Aurora] Running memcached base: $ITER"
	run_memcached "base" $ITER 2>&1 | tee $LOG 
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
	mkdir -p $OUT/memcached/$PERIOD 2> /dev/null
	ARR=`seq 1 $MAX_ITER`
	set -- $ARR
	while [ -n "${1+set}" ];
	do
	    ITER=$1
	    if check_completed $OUT/memcached/$PERIOD/$ITER.out; then
		shift
		continue
	    fi
	    echo "[Aurora] Running memcached with Aurora: Checkpoint period $PERIOD, Iteration $ITER"
	    run_memcached "$PERIOD" $ITER $PERIOD 2>&1 | tee $LOG 
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
    set -- $MUT_ALL_HOSTS
    while [ -n "${1+set}" ];
    do
	HOST=$1
	echo "Accessing all hosts: $HOST"
	ssh $HOST "cd $AURORA_MUT_DIR; ./mutilate -h" > /dev/null 2> /dev/null
	if [ $? != 0 ];then
		echo "[Aurora] Mutilate agent not installed on host($HOST) - please re-run setup.sh"
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

PYTHONPATH=${PYTHONPATH+""}:$(pwd)/dependencies/progbg
export PYTHONPATH
export OUT
export MODE
echo "[Aurora] Creating Fig4b Graph"
python3.7 -m progbg graphing/fig4b.py

