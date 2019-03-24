#!/bin/bash

source $PWD/$1

mkdir -p $OUTPATH/result

wklds=($WKLDS)
exp_type=$3
out_prefix=$2
pwd=$PWD



start_redis () {
	redis_type=$1
	printf "Start Redis server in %s mode\n" $redis_type
	if [ $redis_type == 'mem' ]
	then
		$REDIS --save "" --appendonly no &
	elif [ $redis_type == 'rdb' ]
	then
		$REDIS --save "1 10000000" --appendonly no &
	elif [ $redis_type == 'aof' ]
	then
		$REDIS --save "" --appendonly yes --appendfsync everysec &
	fi
	sleep 2
}

stop_exp () {
        killall redis-server
        sleep 3

        rm -f appendonly.aof dump.rdb slsdump.x 
        touch slsdump.x
}

start_redis_ycsb() {
        wkld=$1
        output=$2
        cd $YCSB_PATH
        ./bin/ycsb load redis -s -P $wkld -p "redis.host=127.0.0.1" -p "redis.port=6379" > $output 
        cd $pwd
        sleep 3
}

run_all_wklds () {
        wkld=$1
        for met in "${@:2}"
        do
                echo bash redis-exp.sh $ROUND $met $wkld $SIZE $OUTPATH/$wkld-$met
                grep "Throughput" -R $OUTPATH/$wkld-$met-* | awk '{print $3}' | python3 meanstd.py > $wkld-$met.sum
        done
}


for ((rnd=0; rnd < $ROUND; rnd++)); do
        for wkld in ${wklds[@]}; do
                echo $wkld
                output=$OUTPATH/$out_prefix-$wkld-$rnd.txt
                wkld=$WKLD_PATH/$wkld
                echo $wkld
                echo $output

                if [ $exp_type == 'sls' ]
                then
                        start_redis mem
                        $SLS cpktstart -p `pidof redis-server` -t $4 -n $5 -f $PWD/slsdump.x -d
                else
                        echo start
                        start_redis $exp_type
                fi

                echo start YCSB benchmark
                start_redis_ycsb $wkld $output

                cd $pwd
                stop_exp
        done
        sleep 3
done

for wkld in ${wklds[@]}; do
        grep "Throughput" -R $OUTPATH/$out_prefix-$wkld-* | awk '{print $3}' | python3 meanstd.py > $out_prefix-$wkld.sum
done

python3 merge.py $WKLDS $out_prefix > $OUTPATH/result/$out_prefix.sum
rm -f *.sum

