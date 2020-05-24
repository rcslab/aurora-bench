#!/usr/local/bin/bash

set -euo

TEST="redis-server"
SLSCTL="/root/sls/tools/slsctl/slsctl"
OID="5"
BACKEND="slos"
CKPTFREQ="20"

AURORADIR="./aurora"
OUTDIR="./output/"
CONFFILE="$OUTDIR/aurora.conf"
DTRACE="$AURORADIR/stages.d"
DTRACEFILE="$OUTDIR/stages.csv"
DELTA="yes"

# Check if we're doing delta checkpointing
if [ "$DELTA" == "yes" ]
then
    DELTACONF="-d"
else
    DELTACONF=""
fi

echo "BACKEND,$BACKEND" >> "$CONFFILE"
echo "CKPTFREQ,$CKPTFREQ" >> "$CONFFILE"
echo "DELTA,$DELTA" >> "$CONFFILE"

#dtrace -s "$DTRACE" > "$DTRACEFILE" &

"$SLSCTL" partadd -o "$OID" -b "$BACKEND" -t "$CKPTFREQ" -d
"$SLSCTL" attach -o "$OID" -p `pidof $TEST`
"$SLSCTL" checkpoint -o "$OID"

#sleep "$SLEEP"

#pkill -SIGKILL "$TEST"

#sleep 1

#"$SLSCTL" restore -o "$OID"
