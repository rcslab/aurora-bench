#!/usr/local/bin/bash
. aurora.config
. helpers/util.sh
setup_script

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
	--num=50000000 \
	--key_size=48 \
	--db=/testmnt/tmp-db \
	--duration=60 \
	--histogram=1 \
	--write_buffer_size=$((16 << 30)) \
	--disable_auto_compactions \
	--threads=24 \
	"${@:2}"
    cd -
}

run_base_wal()
{
    DIR=$OUT/rocksdb/base-wal
    mkdir -p $DIR
    echo "[Aurora] Running Rocksdb Baseline: WAL"

    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
	    continue
	fi
	setup_zfs >> $LOG 2>> $LOG
	db_bench baseline --sync=true --disable_wal=false > /tmp/out
	teardown_zfs >> $LOG 2>> $LOG
	mv /tmp/out $DIR/$ITER.out
    done
}

run_base_nowal()
{
    DIR=$OUT/rocksdb/base-nowal
    mkdir -p $DIR
    echo "[Aurora] Running Rocksdb Baseline: No WAL"
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
	    continue
	fi

	setup_zfs >> $LOG
	db_bench baseline --sync=false --disable_wal=true > /tmp/out
	teardown_zfs
	mv /tmp/out $DIR/$ITER.out
    done
}

stripe_setup_wal()
{
    gstripe load
    gstripe stop "$STRIPENAME"
    gstripe stop "st1"
    gstripe create -s "$STRIPESIZE" -v "$STRIPENAME" $ROCKS_STRIPE1
    gstripe create -s "$STRIPESIZE" -v "st1" $ROCKS_STRIPE2
    DISK="stripe/$STRIPENAME"
    DISKPATH="/dev/$DISK"

    aursetup

}

stripe_teardown_wal()
{
    aurteardown

    aurunstripe
    gstripe destroy "st1"
}

run_aurora_nowal()
{
    DIR=$OUT/rocksdb/aurora-nowal
    mkdir -p $DIR

    echo "[Aurora] Running Rocksdb SLS: No WAL"
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
	    continue
	fi

	#setup_aurora >> $LOG 2>> $LOG
	stripe_setup_wal
	$AURORACTL partadd -o 1 -d -t 100 -b "slos" >> $LOG 2>> $LOG

	db_bench baseline --sync=false --disable_wal=true > /tmp/out &
	sleep 2

	pid=`pidof db_bench`
	$AURORACTL attach -o 1 -p $pid 2>> $LOG >> $LOG
	$AURORACTL checkpoint -o 1 -r >> $LOG 2>> $LOG

	wait

	stripe_teardown_wal

	#teardown_aurora >> $LOG 2>> $LOG
	mv /tmp/out $DIR/$ITER.out
    done
}

run_aurora_wal()
{
    DIR=$OUT/rocksdb/aurora-wal
    mkdir -p $DIR
    echo "[Aurora] Running Rocksdb SLS: WAL"
    for ITER in `seq 0 $MAX_ITER`
    do
	if check_completed "$DIR/$ITER.out"; then
	    continue
	fi

	# We need custom stripes for the WAL as we use a seperate stripe to directly write to for the WAL
	stripe_setup_wal

	db_bench sls --sync=true --disable_wal=false > /tmp/out

	stripe_teardown_wal

	teardown_aurora >> $LOG 2>> $LOG
	mv /tmp/out $DIR/$ITER.out
    done
}

. helpers/util.sh
. aurora.config

clear_log

mkdir -p $OUT/rocksdb

run_base_wal

run_base_nowal

run_aurora_wal

run_aurora_nowal

PYTHONPATH=$PYTHONPATH:$(pwd)/dependencies/progbg
export PYTHONPATH
export OUT

python3.7 -m progbg --debug graphing/fig5.py
