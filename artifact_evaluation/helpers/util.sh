#!/bin/sh
setup_script()
{
	. aurora.config
	. $SRCROOT/tests/aurora
	. aurora.config
	MAX_ITER=1
}

setup_aurora()
{
	aurteardown #1>/dev/null 2>/dev/null
	aurstripe #1> /dev/null 2> /dev/null
	#createmd
	aursetup
}

teardown_aurora()
{
	aurteardown #>/dev/null 2>/dev/null
	aurunstripe
	#destroymd
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
    gstripe create -s 65536 -v st0 $STRIPEDISKS
    newfs -j -S 4096 -b 65536 /dev/stripe/st0
    mount /dev/stripe/st0 /testmnt
}

teardown_ffs()
{
    umount /testmnt
    gstripe destroy st0
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

	zfs set sync=disabled benchmark
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



