#!/bin/bash 

server="/usr/home/hongbo/sls-bench/redis/src/redis-server"
benchmark="/usr/home/hongbo/sls-bench/redis/src/redis-benchmark"

run_redis () {
	total=$1
	prefix=$2
	for ((i=1; i<=$total; i++)); do
		printf "Round %02d\n" $i
		$server ${@:3} &
		sleep 2
		/usr/bin/time -l $benchmark -n 100000 > $prefix-`printf "%02d" $i`.txt 2> $prefix-`printf "%02d" $i`.tim
		sleep 2
		killall redis-server
		sleep 2
	done
}

run_ycsb () {
}

run_redis $@
