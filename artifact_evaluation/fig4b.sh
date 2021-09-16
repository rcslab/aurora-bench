#!/bin/sh
. aurora.config
. helpers/util.sh

AURORACTL=$SRCROOT/tools/slsctl/slsctl
MUTILATE=$(pwd)/dependencies/mutilate/mutilate
MEMCACHED_THREADS=4
MEMCACHED_PORT=11211
MEMCACHED_PIDFILE="/tmp/memcached.pid"
MEMCACHED_CONNECTIONS=32768

MUTILATE_THREADS=12
MUTILATE_CONNECTIONS=12
MUTILATE_WARMUP=5
MUTILATE_TIME=15

start_clients()
{
    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	echo "[Aurora] Starting Mutilate Agent at $1"
	CHECK=`ssh $1 'pidof mutilate'`
	if [ ! -z "$CHECK" ];then
		# We are being safe and killing and starting our own mutilate 
		# with arguments we want.
		echo "[Aurora] Old Mutilate found on $1 - cleaning up"
		ssh $1 'kill -TERM `pidof mutilate`'
		SOCKSTAT=`ssh $1 'sockstat | grep 5556'`
		while [ ! -z "$SOCKSTAT" ];
		do
			echo "[Aurora] Socket still open - waiting"
			echo $SOCKSTAT
			SOCKSTAT=`ssh $1 'sockstat | grep 5556'`
			sleep 5
		done
	fi
	ssh $1 "cd $AURORA_CLIENT_DIR/mutilate; ./mutilate -T 16 -A -v" &
	shift
    done
}

stop_clients()
{
    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	echo "[Aurora] Killing Mutilate Agents at $1"
	ssh $1 "kill -TERM \`pidof mutilate\`" 
	shift
    done
}

run_memcached()
{
    CHILD_DIR=$1
    ITER=$2
    if [ "$#" -gt 2 ]; then
	FREQ=$3
	SLS="on"
    else
	SLS="off"
    fi

    kill -KILL `pidof memcached`
    kill -KILL `pidof mutilate`
    stop_clients
    SOCKSTAT=`sockstat | grep $MEMCACHED_PORT`
    while [ ! -z "$SOCKSTAT" ];
    do
	echo "[Aurora] Socket still open - waiting"
	SOCKSTAT=`sockstat | grep $MEMCACHED_PORT`
	kill -KILL `pidof memcached`
	sleep 5
    done


    start_clients

    if [ "$SLS" = "on" ]; then
	setup_aurora $FREQ >> $LOG 2>> $LOG
	$AURORACTL partadd -o 1 -d -t $FREQ -b $BACKEND >> $LOG 2>> $LOG
    fi

    USER="-u root" 
    ADDRESS="-l $AURORA_MEMCACHED_URL"
    THREADS="-t $MEMCACHED_THREADS"
    PORT_A="-p $MEMCACHED_PORT"
    PIDFILE="-P $MEMCACHED_PIDFILE"
    CONNECTIONS="-c $MEMCACHED_CONNECTIONS"

    memcached $USER $ADDRESS $THREADS $PORT_A $PIDFILE $CONNECTIONS &
    sleep 1

    if [ "$SLS" = "on" ]; then
	pid=`pidof memcached`
	echo "[Aurora] Attaching memcached Server to Aurora: $pid"
	$AURORACTL attach -o 1 -p $pid >> $LOG 2>> $LOG
    else
	pid=`pidof memcached`
	echo "[Aurora] memcached Server at: $pid"
    fi

    echo "[Aurora] Loading data to memcached server at $ADDRESS:$MEMCACHED_PORT"
    echo "[Aurora] Loading data to memcached server at $ADDRESS:$MEMCACHED_PORT" >> $LOG 2>> $LOG
    $MUTILATE -s "$AURORA_MEMCACHED_URL:$MEMCACHED_PORT" --loadonly

    if [ "$SLS" = "on" ]; then
	$AURORACTL checkpoint -o 1 -r >> $LOG 2>> $LOG
    fi


    HOSTS=""
    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	HOSTS="-a $1 ${HOSTS}"
	shift
    done

    echo "[Aurora] Starting Running Mutilate $1"
    $MUTILATE -B -T $MUTILATE_THREADS \
	-c $MUTILATE_CONNECTIONS \
	-w $MUTILATE_WARMUP \
	-Q $MUTILATE_QPS \
	-q $MUTILATE_TARGET_QPS \
	-t $MUTILATE_TIME \
	-s $AURORA_MEMCACHED_URL:$MEMCACHED_PORT --noload \
	$HOSTS > /tmp/out &

    sleep 1
    PID=`pidof mutilate`
    CHECK_ALIVE=`kill -0 $PID`
    CHECK_ALIVE=$?
    while [ "$CHECK_ALIVE" -eq 0 ];
    do
	ERR=`grep "BEV_EVENT_ERROR" aurora.log`
	if [ ! -z "$ERR" ];then
		echo "[Aurora] Problem with mutilate - restart asked"
		kill -KILL $PID
		kill -TERM `pidof memcached`
		kill -TERM `pidof mutilate`
		teardown_aurora
		stop_clients
		return 1
	fi
	CHECK_ALIVE=`kill -0 $PID`
	CHECK_ALIVE=$?
	sleep 1
    done

    kill -TERM `pidof memcached`

    if [ "$SLS" = "on" ]; then
	teardown_aurora  >> $LOG 2>> $LOG
    fi

    if [ $? -eq 124 ]; then
	echo "[Aurora] Issue with memcached timing out - restart is required"
	exit 1
    fi

    mv /tmp/out $OUT/memcached/$CHILD_DIR/$ITER.out
    fsync $OUT/memcached/$CHILD_DIR/$ITER.out
    # Wait for port to become available again
    
    stop_clients

    echo "[Aurora] Done"
    return 0
}

run_base()
{
    mkdir -p $OUT/memcached/base 2> /dev/null

    ARR=`seq 0 $MAX_ITER`
    set -- $ARR
    while [ -n "$1" ];
    do
	ITER=$1
	if check_completed $OUT/memcached/base/$ITER.out; then
	    shift
	    continue
	fi
	echo "[Aurora] Running memcached base: $ITER"
	run_memcached "base" $ITER >> $LOG 2>> $LOG
	if [ "$?" -eq 0 ];then
		shift
	fi
	sleep 20
    done
    echo "[Aurora] Done running memcached base"

}

run_aurora()
{
    for f in `seq $MIN_FREQ $FREQ_STEP $MAX_FREQ`
    do
	mkdir -p $OUT/memcached/$f 2> /dev/null
	ARR=`seq 0 $MAX_ITER`
	set -- $ARR
	while [ -n "$1" ];
	do
	    ITER=$1
	    if check_completed $OUT/memcached/$f/$ITER.out; then
		shift
		continue
	    fi
	    echo "[Aurora] Running memcached with Aurora: Checkpoint period $f, Iteration $ITER"
	    run_memcached "$f" $ITER $f >> $LOG 2>> $LOG
	    if [ "$?" -eq 0 ];then
		shift
	    fi
	    sleep 20
	done
    done
    echo "[Aurora] Done running memcached with Aurora"
}


check_mutilate_install()
{
    $MUTILATE -h > /dev/null 2> /dev/null
    if [ $? != 0 ];then
	    echo "[Aurora] Mutilate agent not installed on current machine - please re-run setup.sh"
	    exit 1
    fi

    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	ssh $1 "cd $AURORA_CLIENT_DIR/mutilate; ./mutilate -h" > /dev/null 2> /dev/null
	if [ $? != 0 ];then
		echo "[Aurora] Mutilate agent not installed on host($1) - please re-run setup.sh"
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

PYTHONPATH=$PYTHONPATH:$(pwd)/dependencies/progbg
export PYTHONPATH
export OUT
export MODE
echo "[Aurora] Creating Fig4b Graph"
python3.7 -m progbg graphing/fig4b.py

