#!/bin/sh

# This script is to be run from its current working directory.

. ../aurora.config

export SRCROOT
export BENCHROOT

# Create 
. $SRCROOT/tests/aurora

aurteardown > /dev/null 2> /dev/null

createmd

DSCRIPT="$SRCROOT/scripts/ckpt.d"
REDISSRV="redis-server"
CONF="redis.freebsd.conf"
TMPFILE="$OUT/redisinput"
DPATH="$OUT/dtrace.output"
# Add 50 MB of data to Redis. Redis has massive write amplification,
# with its resident set size typically ballooning to 10x the amount
# of data being inserted to it for a total memory usage of around 500MB.
SIZE="50"

pkill $REDISSRV

# Wait for the server to die
wait 1

export DISK
export DISKPATH
export MNT

# Create the absolute minimal root for Redis
aursetup
installminroot

# The output of dtrace is piped to the proper file by the parent script.
$DSCRIPT > $DPATH &
DTRACEPID="$!"

cp $CONF "$MNT/$CONF"
chroot $MNT $REDISSRV $CONF &

sleep 1

REDISPID="$( pidof redis-server )"
echo "PID is $REDISPID"

# For some reason, directly piping redisgen.py breaks the pipe.
python3 "$BENCHROOT/artifact_evaluation/table7-aurora/redisgen.py" "$SIZE"  > "$TMPFILE"
cat "$TMPFILE" | redis-cli --pipe 
rm "$TMPFILE"

# Checkpoint to the disk, so that the results are comparable to CRIUs.
slsosdcheckpoint $REDISPID

kill $REDISPID
kill $DTRACEPID

# Wait for the workload to die so that the unmount succeeds.
sleep 1

echo ""
echo "[Aurora] Aurora VS CRIU - Table 7, Aurora Column"
echo "================================================"
OUTFILE=../graphs/table7-aurora-column.txt
cat $DPATH | grep "Metadata copy"  | sed "s/Metadata copy/Metadata copy/"  >  $OUTFILE
cat $DPATH | grep "Shadowing the objects" | sed "s/Shadowing the objects/Data copy		/" >> $OUTFILE
cat $DPATH | grep "Application stop time" | sed "s/Application stop time\t/Total Stop Time/" >> $OUTFILE
cat $DPATH | grep "Task IO" | sed "s/Task IO\t\t/Write Time/" >> $OUTFILE

cat $OUTFILE

echo ""

echo "[Aurora] Wrote $(( $( sysctl -n aurora.data_sent ) + \
    $( sysctl -n aurora.data_received ) )) bytes"

echo "[Aurora] Tearing down"
aurteardown > /dev/null 2> /dev/null
umount "$MNT/dev" > /dev/null 2> /dev/null
slsunmount > /dev/null 2>/dev/null
unloadsls > /dev/null 2>/dev/null
unloadslos >/dev/null 2>/dev/null

aurteardown >/dev/null 2>/dev/null
