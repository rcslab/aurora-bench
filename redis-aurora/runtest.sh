#/usr/local/bin/bash

set -euo

#Script for the Redis benchmarks. Run at the base Redis directory.

REDISDIR="/root/sls-bench/redis/"
SERVER="redis-server"
CLIENT="redis-benchmark"
SERVERBIN="$REDISDIR/src/$SERVER"
CLIENTBIN="$REDISDIR/src/$CLIENT"
OUTDIR="./output/"
OUTFILE="$OUTDIR/redis.csv"
CONFFILE="$OUTDIR/redis_benchmark.conf"

# The tests to be run by the client
TESTS="SET,GET"

# Number of redis clients, need a lot for throughput
CLIENTNO="16"

# Number of requests
REQUESTS=$((1024 * 1024 * 32))

# Size of request values controls memory usage along with keyspace
VALSIZE="4096"

# Request pipelining depth, amortizes latency
PIPELINE="10"

#Size of the key space, controls total memory usage
KEYSPACE=$((1024 * 1024 * 1024))

mkdir "$OUTDIR"

# Dump the conf into a file and move it to the output
python3 aurora/config.py
mv redis.conf.csv "$OUTDIR"

# XXX Dump the benchmark parameters to the output too
echo "TESTS,$TESTS" >> "$CONFFILE"
echo "CLIENTNO,$CLIENTNO" >> "$CONFFILE"
echo "REQUESTS,$REQUESTS" >> "$CONFFILE"
echo "VALSIZE,$VALSIZE" >> "$CONFFILE"
echo "PIPELINE,$PIPELINE" >> "$CONFFILE"
echo "KEYSPACE,$KEYSPACE" >> "$CONFFILE"

# Load the SLS
./aurora/load.sh

# XXX Dump the benchmark parameters to the output too
# Run the server in the background
"$SERVERBIN" "$REDISDIR/redis.conf" &

# Sleep just a bit to let the server set up
sleep 1

./aurora/setup.sh

#Run the benchmark
"$CLIENTBIN" -t "$TESTS" -c "$CLIENTNO" -n "$REQUESTS" -d "$VALSIZE" \
    -P "$PIPELINE" -k "$KEYSPACE" 
#    -P "$PIPELINE" -k "$KEYSPACE" -q --csv 1> "$OUTFILE"

# Kill the server
pkill -SIGKILL "$SERVER"

sleep 2

# Unload the SLS
./aurora/unload.sh
#./aurora/cleanup.sh
