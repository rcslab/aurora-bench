#!/bin/bash 

server="/usr/home/hongbo/sls-bench/redis/src/redis-server"
sls="/usr/home/hongbo/sls/tools/slsctl/slsctl"
benchmark="/usr/home/hongbo/sls-bench/redis/src/redis-benchmark"

run_redis () {
	sls_duration=$1
	sls_count=$2
	total=$3
	prefix=$4
	for ((i=1; i<=$total; i++)); do
		printf "Round %02d\n" $i
		$server ${@:5} &
		sleep 2
		$sls ckptstart -p `pidof redis-server` -t $sls_duration -n $sls_count -f $PWD/slsdump.x -d
		sleep 1
		/usr/bin/time -l $benchmark -n 100000 > $prefix-`printf "%02d" $i`.txt 2> $prefix-`printf "%02d" $i`.tim
		sleep 2
		killall redis-server
		sleep 2
	done
}

run_redis $@
bash sum.sh $4
