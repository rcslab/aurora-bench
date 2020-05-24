#/bin/bash

SERVER="redis-server"
CLIENT="redis-benchmark"
OUTDIR="output"

# Kill the server and benchmark
pkill "$SERVER"
pkill "$CLIENT"
pkill dtrace

# Clean up the output
rm -rf "$OUTDIR"

# Clean up any Redis backup files
rm -f *.rdb *.aof

# Unload Aurora itself
 ./aurora/unload.sh

 gstripe destroy st0
