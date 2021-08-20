#!/usr/local/bin/bash
. aurora.config
. helpers/util.sh

AURORACTL=$SRCROOT/tools/slsctl/slsctl


db_bench() {
    cd dependencies/rocksdb
    $1/db_bench \
	--benchmarks=fillbatch,mixgraph \
	--use_direct_io_for_flush_and_compaction=true \
	--use_direct_reads=true \
	--cache_size=$((256 << 20)) \
	--key_dist_a=0.002312 \
	--key_dist_b=0.3467 \
	--keyrange_dist_a=14.18 \
	--keyrange_dist_b=0.3467 \
	--keyrange_dist_c=0.0164 \
	--keyrange_dist_d=-0.08082 \
	--keyrange_num=30 \
	--value_k=0.2615 \
	--value_sigma=25.45 \
	--iter_k=2.517 \
	--iter_sigma=14.236 \
	--mix_get_ratio=0.83 \
	--mix_put_ratio=0.14 \
	--mix_seek_ratio=0.03 \
	--sine_mix_rate_interval_milliseconds=5000 \
	--sine_a=1000 \
	--sine_b=0.000073 \
	--sine_d=4500 \
	--perf_level=2 \
	--num=$ROCKSDB_NUM \
	--key_size=48 \
	--db=/testmnt/tmp-db \
	--duration=$ROCKSDB_DUR \
	--histogram=1 \
	--write_buffer_size=$((16 << 30)) \
	--disable_auto_compactions \
	--threads=24 \
	"${@:2}"
    cd -
    return $?
}

run_base_wal()
{
    DIR=$OUT/rocksdb/base-wal
    mkdir -p $DIR
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
	    continue
	fi
	echo "[Aurora] Running Rocksdb Baseline: WAL, Iteration $ITER"
	setup_zfs_rocksdb >> $LOG 2>> $LOG
	db_bench baseline --sync=true --disable_wal=false > /tmp/out
	teardown_zfs >> $LOG 2>> $LOG
	mv /tmp/out $DIR/$ITER.out
	fsync $DIR/$ITER.out
    done
}

run_base_nowal()
{
    DIR=$OUT/rocksdb/base-nowal
    mkdir -p $DIR
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
	    continue
	fi

	echo "[Aurora] Running Rocksdb Baseline: No WAL, Iteration $ITER"
	setup_zfs_rocksdb >> $LOG 2>> $LOG
	db_bench baseline --sync=false --disable_wal=true > /tmp/out
	teardown_zfs
	mv /tmp/out $DIR/$ITER.out
	fsync $DIR/$ITER.out
    done
}

stripe_setup_wal()
{
    CKPT_FREQ=$1

    gstripe load
    gstripe stop "$STRIPENAME"
    gstripe stop "st1"

    # Sets up the two stripes needed for the RocksDB Aurora benchmark 
    # STRIPENAME is the default stripe used by all benchmarks which is used by the SLS and SLOS
    # The secondary stripe "st1" is used for the persistent storage for the WAL.
    # During operation operatiosn are written to the WAL (which is on st1), when this wal fills, Aurora
    gstripe create -s "$STRIPESIZE" -v "$STRIPENAME" $ROCKS_STRIPE1
    set -- $ROCKS_STRIPE2
    if [ $# -gt 1 ]; then
	gstripe create -s "$STRIPESIZE" -v "st1" $ROCKS_STRIPE2
	ln -s /dev/stripe/st1 /dev/wal
    else
	ln -s /dev/$ROCKS_STRIPE2 /dev/wal
    fi


    DISK="stripe/$STRIPENAME"
    DISKPATH="/dev/$DISK"

    aursetup
    if [ -z "$CKPT_FREQ" ]; then
	    sysctl aurora_slos.checkpointtime=$CKPT_FREQ
    else
	    sysctl aurora_slos.checkpointtime=$MAX_FREQ
    fi

}

stripe_teardown_wal()
{
    aurteardown

    aurunstripe
    gstripe destroy "st1"
    umount /testmnt/dev > /dev/null 2> /testmnt/dev
    rm /dev/wal
}

run_aurora_nowal()
{
    DIR=$OUT/rocksdb/aurora-nowal
    mkdir -p $DIR

    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
	    continue
	fi

	echo "[Aurora] Running Rocksdb SLS: No WAL, Iteration $ITER"
	rm /tmp/out 2> /dev/null > /dev/null
	stripe_setup_wal $MAX_FREQ >> $LOG 2>> $LOG
	$AURORACTL partadd -o 1 -d -t $MIN_FREQ -b $BACKEND >> $LOG 2>> $LOG

	db_bench baseline --sync=false --disable_wal=true > /tmp/out &
	FUNC_PID="$!"
	if [ "$MODE" = "VM" ]; then
		sleep 2
	else
		sleep 15
	fi

	pid=`pidof db_bench`
	$AURORACTL attach -o 1 -p $pid 2>> $LOG >> $LOG
	$AURORACTL checkpoint -o 1 -r >> $LOG 2>> $LOG

	wait $FUNC_PID
	if [ $? -eq 124 ];then
		echo "[Aurora] Issue with db_bench, restart required"
		exit 1
	fi
	sleep 2

	stripe_teardown_wal >> $LOG 2>> $LOG

	mv /tmp/out $DIR/$ITER.out
	fsync $DIR/$ITER.out
    done
}

run_aurora_wal()
{
    DIR=$OUT/rocksdb/aurora-wal
    stripe_teardown_wal > /dev/null 2> /dev/null
    mkdir -p $DIR
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
		continue
	fi

	# We need custom stripes for the WAL as we use a seperate stripe to directly write to for the WAL
	echo "[Aurora] Running Rocksdb SLS: WAL, Iteration $ITER"
	stripe_setup_wal $MAX_FREQ

	db_bench sls --sync=true --disable_wal=false > /tmp/out

	# Wait for the final checkpoint to be done

	stripe_teardown_wal

	teardown_aurora >> $LOG 2>> $LOG
	mv /tmp/out $DIR/$ITER.out
	fsync $DIR/$ITER.out
    done
}

setup_script
clear_log
if [ "$MODE" = "VM" ]; then
	MAX_ITER=0
else
	MAX_ITER=0
fi
echo "[Aurora] Running with $MAX_ITER iterations"

mkdir -p $OUT/rocksdb

run_base_wal

run_base_nowal

run_aurora_wal

run_aurora_nowal

echo "[Aurora] Creating RocksDB Graphs"
PYTHONPATH=$PYTHONPATH:$(pwd)/dependencies/progbg
export PYTHONPATH
export OUT

python3.7 -m progbg --debug graphing/fig5.py
