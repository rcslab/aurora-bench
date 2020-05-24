#!/usr/local/bin/bash

SLSDIR="/root/sls/"
REDISDIR="/root/sls-bench/redis/"
OUTDIR="/output"

set -euo

#gstripe destroy st0
#gstripe create -s 1048576 -v st0 vtbd0 vtbd1 vtbd2 vtbd3
#gstripe create -s 65536 -v st0 nvd0 nvd1 nvd2 nvd3
#gstripe destroy st0
#gstripe create -s 65536 -v st0 nvd0 nvd1 nvd2 nvd3
#gstripe create -s 65536 -v st0 vtbd1 vtbd2 vtbd3
#gstripe create -s 1048576 -v st0 vtbd1 vtbd2 vtbd3

#DRIVE=/dev/stripe/st0

DRIVE=/dev/vtbd1
#make -j5 -DWITH_DFLAGS #-DTEST

"$SLSDIR"/tools/newosd/newosd $DRIVE

kldload "$SLSDIR"/slos/slos.ko

mount -rw -t slsfs $DRIVE /testmnt

kldload "$SLSDIR"/kmod/sls.ko

sysctl aurora.async_slos=1
sysctl aurora.sync_slos=0
sysctl aurora > "$REDISDIR/$OUTDIR/aurora.sysctl"

#fio trace/test.fio

#echo "hello" > /testmnt/hello
#kldload kmod/sls.ko
#filebench -f benchmarks/scripts/randomrw1.f
#filebench -f benchmarks/scripts/randomrw.f
##sleep 10
#filebench -f benchmarks/scripts/fileserver.f

#kldunload sls
#umount /testmnt
#kldunload slos

#mount -rw -t slsfs /dev/vtbd1 /testmnt


#mkdir -p /testmnt/dingdong/hello/2/

