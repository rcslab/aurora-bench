#!/bin/sh
. aurora.config
. helpers/util.sh

AURORACTL=$SRCROOT/tools/slsctl/slsctl
REDIS_PORT=9785
REDIS_THREADS=12


run_redis_ycsb()
{
    CHILD_DIR=$1
    ITER=$2
    if [ "$#" -gt 2 ]; then
	FREQ=$3
	SLS="on"
    else
	SLS="off"
    fi

    kill -TERM `pidof redis-server` 2> /dev/null > /dev/null

    YCSB_ROOT=dependencies/ycsb-0.17.0
    YCSB=$YCSB_ROOT/bin/ycsb.sh

    echo "[Aurora] Starting Redis Server at $AURORA_REDIS_URL"
    echo "[Aurora] Starting Redis Server at $AURORA_REDIS_URL" >> $LOG

    if [ "$SLS" = "on" ]; then
	setup_aurora $FREQ >> $LOG 2>> $LOG
	echo "[Aurora] Redis Server Aurora $BACKEND - $FREQ"
	$AURORACTL partadd -o 1 -d -t $FREQ -b $BACKEND >> $LOG 2>> $LOG
    else
	# Setup the database on the stripe as well - use ffs
	setup_ffs >> $LOG 2>> $LOG
    fi

    mkdir -p $AURORA_REDIS_DIR
    redis-server redis.conf >> $LOG

    if [ "$SLS" = "on" ]; then
	pid=`pidof redis-server`
	echo "[Aurora] Attaching Redis Server to Aurora: $pid"
	$AURORACTL attach -o 1 -p $pid 2>> $LOG >> $LOG
    fi
    

    SERVER="-p redis.host=$AURORA_REDIS_URL"
    PORT="-p redis.port=$REDIS_PORT"
    PASS="-p redis.password=$AURORA_REDIS_PASSWORD"
    THREADS="-threads $REDIS_THREADS"
    OPS="-p operationcount=$REDIS_OP_COUNT"

    $YCSB load redis -P $YCSB_ROOT/workloads/workloada \
	$SERVER $PORT $PASS -p recordcount=$REDIS_RECORD_COUNT >> $LOG 2>> $LOG

    if [ "$SLS" = "on" ]; then
	$AURORACTL checkpoint -o 1 -r >> $LOG 2>> $LOG
    fi

    CLIENT_ROOT=$AURORA_CLIENT_DIR/ycsb-0.17.0
    WORKLOAD=$CLIENT_ROOT/workloads/workloada
    YCSB_CLIENT=$CLIENT_ROOT/bin/ycsb.sh
    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	ssh $1 "$YCSB_CLIENT run redis -P $WORKLOAD $SERVER $PORT $PASS $THREADS $OPS" > /tmp/$1.log 2> /dev/null &
	shift
    done

    wait

    echo "[Aurora] Killing Redis Server at $AURORA_REDIS_URL"
    kill -TERM `pidof redis-server`
    # Clean up aurora
    if [ "$SLS" = "on" ]; then
	teardown_aurora >> $LOG 2>> $LOG
    else
	teardown_ffs >> $LOG 2>> $LOG
    fi

    mkdir -p $OUT/redis/$CHILD_DIR

    touch /tmp/out

    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	cat /tmp/$1.log >> /tmp/out

	mv /tmp/out $OUT/redis/$CHILD_DIR/$ITER.out
	fsync $OUT/redis/$CHILD_DIR/$ITER.out

	# Just making sure we dont accidently use this file somewhere although it shouldn't
	rm /tmp/$1.log
	shift
    done

    rm /tmp/out 2> /dev/null > /dev/null

}


run_base()
{
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed $OUT/redis/base/$ITER.out; then
	    continue
	fi
	echo "[Aurora] Running Redis base: $ITER"
	run_redis_ycsb "base" $ITER
    done
    echo "[Aurora] Done running Redis base"
}

run_aurora()
{
    for f in `seq $MIN_FREQ $FREQ_STEP $MAX_FREQ`
    do
	echo "[Aurora] Running redis with Aurora: Checkpoint period $f"
	for ITER in `seq 0 $MAX_ITER`
	do
	    if check_completed $OUT/redis/$f/$ITER.out; then
		continue
	    fi
	    echo "[Aurora] Running Redis Aurora Iteration $ITER"
	    run_redis_ycsb "$f" $ITER $f
	done
    done
    echo "[Aurora] Done running Redis Aurora"

}

mkdir -p $OUT/redis
mkdir -p $AURORA_REDIS_DIR
setup_script

if [ "$MODE" = "VM" ]; then
	MAX_ITER=1
else
	MAX_ITER=9
fi
echo "Running with $MAX_ITER iterations"


# Create the redis conf
sed "s/PASSWORD/$AURORA_REDIS_PASSWORD/g; s/URL/$AURORA_REDIS_URL/g; s/DIR/$AURORA_REDIS_DIR_SED/g;" \
    helpers/redis.conf.template > redis.conf

clear_log

run_base 

run_aurora 

PYTHONPATH=$PYTHONPATH:$(pwd)/dependencies/progbg
export PYTHONPATH
export OUT
export MODE
echo "[Aurora] Creating Fig4a Graph"
python3.7 -m progbg graphing/fig4a.py

