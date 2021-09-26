#!/bin/sh

# This script is to be run from its current working directory.

. ../aurora.config

export BENCHROOT

. $SRCROOT/tests/aurora
. minroot

mkdir -p ../graphs

REDISSRV="redis-server"
CONF="redis.freebsd.conf"
TMPFILE="$OUT/redisinput"
# Add 50 MB of data to Redis. Redis has massive write amplification,
# with its resident set size typically ballooning to 10x the amount
# of data being inserted to it for a total memory usage of around 500MB.
SIZE="50"

pkill $REDISSRV

# Create a Redis instance.
cp $CONF "$MNT/$CONF"
$REDISSRV $CONF &

sleep 1

REDISPID="$( pidof redis-server )"
echo "PID is $REDISPID"

# For some reason, directly piping redisgen.py breaks the pipe.
python3 "$BENCHROOT/artifact_evaluation/table7-aurora/redisgen.py" "$SIZE"  > "$TMPFILE"
cat "$TMPFILE" | redis-cli --pipe 
rm "$TMPFILE"

time `echo "*1\r\nSAVE\r\n" | redis-cli --pipe`

OUTFILE=../graphs/table7-aurora-column.txt
echo "" > $OUTFILE
echo "[Aurora] Aurora VS CRIU - Table 7, Aurora Column (Time in NANOSECONDS)" >> $OUTFILE
echo "======================================================================" >> $OUTFILE

cat $DPATH | grep "Metadata copy"  | sed "s/Metadata copy/Metadata copy/"  >>  $OUTFILE
cat $DPATH | grep "Shadowing the objects" | sed "s/Shadowing the objects/Data copy		/" >> $OUTFILE
cat $DPATH | grep "Application stop time" | sed "s/Application stop time\t/Total Stop Time/" >> $OUTFILE
cat $DPATH | grep "Task IO" | sed "s/Task IO\t\t/Write Time/" >> $OUTFILE

cat $OUTFILE

echo ""

echo "[Aurora] Wrote $(( $( sysctl -n aurora.data_sent ) + \
    $( sysctl -n aurora.data_received ) )) bytes"

echo "[Aurora] Tearing down"
aurteardown > /dev/null 2> /dev/null
