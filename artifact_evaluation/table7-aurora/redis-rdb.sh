#!/bin/sh

# This script is to be run from its current working directory.

. ../aurora.config
export BENCHROOT

invoke_redis()
{

    pkill $REDISSRV
    sleep 1

    REDISSRV="redis-server"
    CONF="redis.freebsd.conf"

    # Create a Redis instance.
    $REDISSRV $CONF &

    sleep 1

    REDISPID="$( pidof redis-server )"
    return $REDISPID
}


mkdir -p ../graphs

TMPFILE="$OUT/redisinput"
# Add 50 MB of data to Redis. Redis has massive write amplification,
# with its resident set size typically ballooning to 10x the amount
# of data being inserted to it for a total memory usage of around 500MB.
SIZE="50"

# For some reason, directly piping redisgen.py breaks the pipe.
python3 "$BENCHROOT/artifact_evaluation/table7-aurora/redisgen.py" "$SIZE"  > "$TMPFILE"
cat "$TMPFILE" | redis-cli --pipe 

REDISPID=`invoke_redis`
echo "PID is $REDISPID"
echo "BGSAVE"
time `echo "*1\r\nBGSAVE\r\n" | redis-cli --pipe`


REDISPID=`invoke_redis`
echo "PID is $REDISPID"
echo "SAVE"
time `echo "*1\r\nSAVE\r\n" | redis-cli --pipe`

rm "$TMPFILE"

OUTFILE=../graphs/table7-rdb-column.txt
#echo "" > $OUTFILE
#echo "[Aurora] Aurora VS CRIU - Table 7, Aurora Column (Time in NANOSECONDS)" >> $OUTFILE
#echo "======================================================================" >> $OUTFILE
#
#cat $DPATH | grep "Metadata copy"  | sed "s/Metadata copy/Metadata copy/"  >>  $OUTFILE
#cat $DPATH | grep "Shadowing the objects" | sed "s/Shadowing the objects/Data copy		/" >> $OUTFILE
#cat $DPATH | grep "Application stop time" | sed "s/Application stop time\t/Total Stop Time/" >> $OUTFILE
#cat $DPATH | grep "Task IO" | sed "s/Task IO\t\t/Write Time/" >> $OUTFILE

cat $OUTFILE

echo ""

echo "[Aurora] Wrote $(( $( sysctl -n aurora.data_sent ) + \
    $( sysctl -n aurora.data_received ) )) bytes"

echo "[Aurora] Tearing down"
aurteardown > /dev/null 2> /dev/null
