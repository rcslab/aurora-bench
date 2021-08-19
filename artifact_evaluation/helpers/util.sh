#!/bin/sh
setup_script()
{
	. aurora.config
	. $SRCROOT/tests/aurora
	. aurora.config
	MAX_ITER=1
	if [ "$MODE" = "VM" ]; then
	    echo "[Aurora] Running Benchmark in VM Mode"
	    # Freqency of checkpoint max and mins
	    MAX_FREQ=1000
	    MIN_FREQ=100
	    FREQ_STEP=100
	    SETUP_FUNC="createmd"
	    TEARDOWN_FUNC="destroymd"
	    BACKEND="memory"
	    # YCSB Benchmark Values
	    REDIS_OP_COUNT=100000
	    REDIS_RECORD_COUNT=10000

	    # Memcached Benchmark Values
	    MUTILATE_QPS=100
	    MUTILATE_TARGET_QPS=20000
	    MUTILATE_TIME=10

	    # RocksDB Benchmark Values
	else
	    echo "[Aurora] Running Benchmark in Default Mode"
	    # Freqency of checkpoint max and mins
	    MAX_FREQ=100
	    MIN_FREQ=10
	    FREQ_STEP=10
	    SETUP_FUNC="aurstripe"
	    TEARDOWN_FUNC="aurunstripe"
	    BACKEND="slos"

	    # YCSB Benchmark Values
	    REDIS_OP_COUNT=100000
	    REDIS_RECORD_COUNT=10000

	    # Memcached Benchmark Values
	    MUTILATE_QPS=1000
	    MUTILATE_TARGET_QPS=200000
	    MUTILATE_TIME=15

	    # RocksDB Benchmark Values
	fi
}

setup_aurora()
{
	aurteardown > /dev/null 2>/dev/null
	$SETUP_FUNC  > /dev/null 2> /dev/null

	if [ -z "$1" ]; then
		sysctl aurora_slos.checkpointtime=$1
	else
		sysctl aurora_slos.checkpointtime=10
	fi
	aursetup
}

teardown_aurora()
{
	aurteardown > /dev/null 2> /dev/null
	# We pass in DISKPATH cause destroymd requires it but aurunstripe does not require
	# any arguments so does not use it.
	$TEARDOWN_FUNC $DISKPATH
}

clear_log()
{
	echo "" > $LOG
}

check_completed()
{
	if [ -f $1 ]; then
		COUNT=$(wc -l < $1)
		if [ "$COUNT" -eq "0" ]; then
			return 1
		fi
		return 0
	else
		return 1
	fi
}

setup_ffs()
{
    if [ "$MODE" = "VM" ]; then
	echo "Create MD"
	createmd
	newfs -j -S 4096 -b 65536 $DISKPATH
	mount $DISKPATH /testmnt
    else
	gstripe create -s 65536 -v st0 $STRIPEDISKS
	newfs -j -S 4096 -b 65536 /dev/stripe/st0
	mount /dev/stripe/st0 /testmnt
    fi
}

teardown_ffs()
{
    umount -f /testmnt
    if [ "$MODE" = "VM" ]; then
	destroymd $DISKPATH
    else
	gstripe destroy st0
    fi
}

setup_zfs_rocksdb()
{
	set -- $STRIPEDISKS
	ZFS_DISKS=""
	while [ -n "$1" ];
	do
	   ZFS_DISKS="/dev/$1 ${ZFS_DISKS}"
	   shift
	done

	zpool create benchmark $ZFS_DISKS
	zfs create benchmark/testmnt

	zfs set mountpoint=/testmnt benchmark/testmnt
	zfs set recordsize=64k benchmark

	zfs set sync=standard benchmark
	zfs set checksum=off benchmark/testmnt
}

setup_zfs()
{
	CHECKSUM=$1
	set -- $STRIPEDISKS
	ZFS_DISKS=""
	while [ -n "$1" ];
	do
	   ZFS_DISKS="/dev/$1 ${ZFS_DISKS}"
	   shift
	done

	zpool create benchmark $ZFS_DISKS
	zfs create benchmark/testmnt

	zfs set mountpoint=/testmnt benchmark/testmnt
	zfs set compression=lz4 benchmark
	zfs set recordsize=64k benchmark

	zfs set sync=standard benchmark
	if [ "$CHECKSUM" = "on" ]
	then
	    zfs set checksum=on benchmark/testmnt
	else
	    zfs set checksum=off benchmark/testmnt
	fi
}

teardown_zfs()
{
	zfs destroy -r benchmark/testmnt 
	zpool destroy benchmark
}



