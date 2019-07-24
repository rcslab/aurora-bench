#!/bin/bash

redis="/root/sls-bench/redis/src/redis-server"
sls="/usr/home/ryan/sls/tools/slsctl/slsctl"
ycsb="/root/sls-bench/YCSB"
redisbench="/root/sls-bench/redis/src/redis-benchmark"

clean_dump () {
	rm -f appendonly.aof dump.rdb /slsdump.x
}

start_redis () {
	redis_type=$1
	printf "Start Redis server in %s mode\n" $redis_type
	if [ $redis_type == 'mem' ] 
	then
		$redis --save "" --appendonly no &
	elif [ $redis_type == 'rdb' ]
	then
		$redis --save "1 10000000" --appendonly no &
	elif [ $redis_type == 'aof' ]
	then
		$redis --save "" --appendonly yes --appendfsync everysec &
	fi
	sleep 2
}

run_ycsb () {
	echo $@
	pwd=$PWD
	workload=$PWD/$1
	resfile=$PWD/$2
	echo "haha" $PWD $workload $resfile
	cd $ycsb
	./bin/ycsb load redis -s -P $workload -p "redis.host=127.0.0.1" -p "redis.port=6379" > $resfile
	sleep 2
	cd $pwd
}

run_redisbench () {
	benchsize=$1
	resfile=$2
	$redisbench -n $benchsize > $resfile
	sleep 2
}

start_bench () {
	echo "bechmark"
	echo $@
	bench_type=$1
	if [ $bench_type == 'ycsb' ]
	then
		run_ycsb $2 $3-$4.txt	
	elif [ $bench_type == 'redis' ]
	then
		run_redisbench $2 $3-$4.txt	
	fi
}

run_experiment () {
	echo $@
	redis_type=$1
	if [ $redis_type == 'sls' ]
	then
		sls_t=$2
		sls_n=$3
		bench_type=$4
		start_redis mem
		$sls ckptstart -p `pidof redis-server` -t $sls_t -n $sls_n -f slsdump.x -d
		start_bench $bench_type ${@:5}
	else
		bench_type=$2
		start_redis $redis_type
		start_bench $bench_type ${@:3}
	fi

	killall redis-server
	sleep 2
	clean_dump
}

rounds=$1
for ((i=0; i < $rounds; i++)); do
	run_experiment ${@:2} $i
	sleep 5
done
