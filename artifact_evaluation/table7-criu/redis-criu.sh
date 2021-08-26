#!/bin/sh

SRCROOT=/root/

REDISSRV="redis-server"
CKPTDIR="$PWD/criuimage"
CONF="redis.linux.conf"
TMPFILE="redisinput"
# The size in MB
SIZE="50"

# This is to catch debian install
PATH=$PATH:/usr/local/sbin

criu > /dev/null 2> /dev/null
if [ $? -ne 1 ];then
    echo "[Aurora] CRIU not installed please run setup.sh found in this directory"
    exit
fi

pkill $REDISSRV

# Wait for the server to die.
sleep 1

setsid $REDISSRV $CONF &

# Wait for the server to spin up.
sleep 1

# We have to get it by PID, we put the server in
# a new session and $! points to setsid's PID.
REDISPID=$(pidof $REDISSRV)

# For some reason, directly piping redisgen.py breaks the pipe.
echo "[Aurora] Generating redis workload"
./redisgen.py "$SIZE"  > "$TMPFILE"
cat "$TMPFILE" | redis-cli --pipe > /dev/null
rm "$TMPFILE"

mkdir -p $CKPTDIR
echo "[Aurora] Creating TMPFS"
mount -t tmpfs -o size=10g tmpfs $CKPTDIR

echo "[Aurora] Dumping"
criu dump -D $CKPTDIR --shell-job -t $REDISPID --display-stats > $TMPFILE 2> /dev/null

OUTPUT=table7-criu.txt

cat $TMPFILE
echo "" > $OUTPUT
echo "[Aurora] Aurora VS CRIU - Table 7, CRIU Column (Time in MICROSECONDS)"  >> $OUTPUT
echo "====================================================================" >> $OUTPUT

cat $TMPFILE  | grep "Memory dump time" | sed "s/Memory dump time:/Data Copy\t/" >> $OUTPUT
cat $TMPFILE  | grep "Frozen time" | sed "s/Frozen time:/Total Stop Time\t/" >> $OUTPUT
cat $TMPFILE  | grep "Memory write time" | sed "s/Memory write time:/Write Time\t/" >> $OUTPUT
cat $OUTPUT
echo "[Aurora] Results in $(pwd)/$OUTPUT"
umount $CKPTDIR
rm -r $CKPTDIR
