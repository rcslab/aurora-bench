#!/bin/bash

source $PWD/$1

mkdir -p $OUTPATH/result

wklds=($WKLDS)
exp_type=$3
out_prefix=$2
pwd=$PWD

start_redis () {
        echo "+++++ start redis +++++"
	redis_type=$1
	printf "Start Redis server in %s mode\n" $redis_type
        cpuset -l 0-1 $REDIS &
        sleep 5
	if [ $redis_type == 'mem' ]
	then
                $REDIS_CLI config set save ""
                $REDIS_CLI config set appendonly no
	elif [ $redis_type == 'rdb' ]
	then
                $REDIS_CLI config set save "1 0"
                $REDIS_CLI config set appendonly no
	elif [ $redis_type == 'aof' ]
	then
                $REDIS_CLI config set save ""
                $REDIS_CLI config set appendonly yes
                $REDIS_CLI config set appendfsync everysec
        elif [ $redis_type == 'mix' ]
	then
                $REDIS_CLI config set save "5 0"
                $REDIS_CLI config set appendonly yes
                $REDIS_CLI config set appendfsync everysec
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
        echo "+++++ Load YCSB +++++"
        sleep 3
        cpuset -l 2 ./bin/ycsb load redis -s -P $wkld -p "redis.host=127.0.0.1" -p "redis.port=6379" 
        echo "+++++ Start YCSB +++++"

        if [ $exp_type == 'sls' ]
        then
                echo "+++++ start ckpt +++++"
                kldload $SLSKO
                $SLS ckptstart -p `pidof redis-server` -t $3 -f $PWD/slsdump.x -d
        fi
        sleep 5
        cpuset -l 2 ./bin/ycsb run redis -s -P $wkld -p "redis.host=127.0.0.1" -p "redis.port=6379" > $output 
        cd $pwd
        sleep 3
}

for ((rnd=0; rnd < $ROUND; rnd++)); do
        for wkld in ${wklds[@]}; do
                echo "+++++ $wkld $rnd/$ROUND +++++"
                sleep 3
                output=$OUTPATH/$out_prefix-$wkld-$rnd.txt
                wkld=$WKLD_PATH/$wkld

                if [ $exp_type == 'sls' ]
                then
                        start_redis mem
                else
                        start_redis $exp_type
                fi

                start_redis_ycsb $wkld $output $4

                cd $pwd
                if [ $exp_type == 'sls' ]
                then
                        echo "+++++ stop ckpt +++++"
                        $SLS ckptstop -p `pidof redis-server`
                        sleep 5
                        kldunload $SLSKO
                fi
                stop_exp
        done
        sleep 3
done

for wkld in ${wklds[@]}; do
        grep "Throughput" -R $OUTPATH/$out_prefix-$wkld-* | awk '{print $3}' | python3 meanstd.py > $out_prefix-$wkld.sum
done

python3 merge.py $WKLDS $out_prefix > $OUTPATH/result/$out_prefix.sum
rm -f *.sum
