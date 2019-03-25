#!/bin/bash

source $PWD/$1

mkdir -p $OUTPATH/result

wklds=($WKLDS)
exp_type=$3
out_prefix=$2
pwd=$PWD



start_memcached () {
	printf "+++++ Start Memcached server +++++\n"
        $MEMCACHED &
	sleep 2
}

stop_exp () {
        killall memcached
        sleep 3

        rm -f slsdump.x 
        touch slsdump.x
}

start_memcached_ycsb() {
        wkld=$1
        output=$2
        cd $YCSB_PATH
        echo "+++++ Load YCSB +++++"
        ./bin/ycsb load memcached -s -P $wkld -p "memcached.hosts=127.0.0.1" 
        sleep 3
        echo "+++++ Start YCSB +++++"
        ./bin/ycsb run memcached -s -P $wkld -p "memcached.hosts=127.0.0.1" > $output 
        cd $pwd
        sleep 3
}

for ((rnd=0; rnd < $ROUND; rnd++)); do
        for wkld in ${wklds[@]}; do
                echo "+++++ $wkld $rnd/$ROUND +++++"
                output=$OUTPATH/$out_prefix-$wkld-$rnd.txt
                wkld=$WKLD_PATH/$wkld
                echo $wkld
                echo $output

                start_memcached
                if [ $exp_type == 'sls' ]
                then
                        kldload $SLSKO
                        sleep 3
                        echo "+++++ start ckpt +++++"
                        $SLS cpktstart -p `pidof memcached` -t $4 -f $PWD/slsdump.x -d
                        sleep 5
                fi

                start_memcached_ycsb $wkld $output

                cd $pwd
                if [ $exp_type == 'sls' ]
                then
                        echo "+++++ stop ckpt ++++"
                        $SLS ckptstop -p `pidof memcached`
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

