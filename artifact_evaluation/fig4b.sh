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

    timeout 60s memcached $USER $ADDRESS $THREADS $PORT_A $PIDFILE $CONNECTIONS &
    PID=`pidof memcached`

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

    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	echo "[Aurora] Starting Mutilate Agent at $1"
	ssh $1 "cd $AURORA_CLIENT_DIR/mutilate; ./mutilate -T 16 -A -v" &
	shift
    done

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
	$HOSTS > /tmp/out

    kill -15 `pidof memcached`

    if [ "$SLS" = "on" ]; then
	teardown_aurora  >> $LOG 2>> $LOG
    fi

    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	echo "[Aurora] Killing Mutilate Agents at $1"
	ssh $1 "kill -TERM \`pidof mutilate\`" 
	shift
    done


    wait $PID
    if [ $? -eq 124 ]; then
	echo "[Aurora] Issue with memcached timing out - restart is required"
	exit 1
    fi

    mv /tmp/out $OUT/memcached/$CHILD_DIR/$ITER.out
    fsync $OUT/memcached/$CHILD_DIR/$ITER.out
    # Wait for port to become available again
    echo "[Aurora] Done"
}

run_base()
{
    mkdir -p $OUT/memcached/base 2> /dev/null

    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed $OUT/memcached/base/$ITER.out; then
	    continue
	fi
	echo "[Aurora] Running memcached base: $ITER"
	run_memcached "base" $ITER >> $LOG 2>> $LOG
    done
    echo "[Aurora] Done running memcached base"

}

run_aurora()
{
    for f in `seq $MIN_FREQ $FREQ_STEP $MAX_FREQ`
    do
	mkdir -p $OUT/memcached/$f 2> /dev/null
	for ITER in `seq 0 $MAX_ITER`
	do
	    if check_completed $OUT/memcached/$f/$ITER.out; then
		continue
	    fi
	    echo "[Aurora] Running memcached with Aurora: Checkpoint period $f, Iteration $ITER"
	    run_memcached "$f" $ITER $f >> $LOG 2>> $LOG
	done
    done
    echo "[Aurora] Done running memcached with Aurora"
}

setup_script
clear_log
if [ "$MODE" = "VM" ]; then
	MAX_ITER=2
else
	MAX_ITER=3
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

