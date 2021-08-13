#!/bin/sh
. aurora.config
. helpers/util.sh

AURORACTL=$SRCROOT/tools/slsctl/slsctl
REDIS_PORT=9785
REDIS_THREADS=12
REDIS_OP_COUNT=1000000
REDIS_RECORD_COUNT=100000

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

    kill -TERM `pidof redis-server`

    YCSB_ROOT=dependencies/ycsb-0.17.0
    YCSB=$YCSB_ROOT/bin/ycsb.sh

    echo "[Aurora] Starting Redis Server at $AURORA_REDIS_URL"
    echo "[Aurora] Starting Redis Server at $AURORA_REDIS_URL" >> $LOG

    if [ "$SLS" = "on" ]; then
	setup_aurora >> $LOG 2>> $LOG
	$AURORACTL partadd -o 1 -d -t $FREQ -b "slos" >> $LOG 2>> $LOG
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
	echo $1
	ssh $1 "$YCSB_CLIENT run redis -P $WORKLOAD $SERVER $PORT $PASS $THREADS $OPS" > /tmp/$1.log &
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

	# Just making sure we dont accidently use this file somewhere although it shouldn't
	rm /tmp/$1.log
	shift
    done

    rm /tmp/out

}


run_base()
{
    echo "[Aurora] Running Redis base"
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed $OUT/redis/base/$ITER.out; then
	    continue
	fi
	run_redis_ycsb "base" $ITER
    done
    echo "[Aurora] Done running Redis base"
}

run_aurora()
{
    echo "[Aurora] Running Redis Aurora"
    for f in 10 20 30 40 50 60 70 80 90 100
    do
	echo "[Aurora] Running redis with Aurora: Checkpoint period $f"
	for ITER in `seq 0 $MAX_ITER`
	do
	    if check_completed $OUT/redis/$f/$ITER.out; then
		continue
	    fi
	    run_redis_ycsb "$f" $ITER $f
	done
    done
    echo "[Aurora] Done running Redis Aurora"

}

mkdir -p $OUT/redis
mkdir -p $AURORA_REDIS_DIR
setup_script

# Create the redis conf
sed "s/PASSWORD/$AURORA_REDIS_PASSWORD/g; s/URL/$AURORA_REDIS_URL/g; s/DIR/$AURORA_REDIS_DIR_SED/g;" \
    helpers/redis.conf.template > redis.conf

clear_log

run_base 

run_aurora 

PYTHONPATH=$PYTHONPATH:$(pwd)/dependencies/progbg
export PYTHONPATH
export OUT

python3.7 -m progbg graphing/fig4a.py
