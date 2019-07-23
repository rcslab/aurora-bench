#!/usr/local/bin/bash

SLS=$1
ITER="$2"
MIN="$3"
MAX="$4"
STEP="$5"

mkdir data

mkdir data/without
mkdir data/without/logs
mkdir data/with
mkdir data/with/logs

DIR=data/without
CSV=data/without.csv
for i in `seq 1 $ITER`;
do
	CURRENT=$MIN
	echo ""
	echo "ITERATION $i"
	echo ""
	NAME=$i.log
	./run.sh  > $DIR/logs/$NAME
	grep "Time: " $DIR/logs/$NAME | cut -f 2 -w - >> $CSV
done

DIR=data/with
for i in `seq 1 $ITER`;
do
	CURRENT=$MIN
	echo ""
	echo "ITERATION $i SLS"
	echo ""
	while [ $MAX -gt $CURRENT ] 
	do
		echo ""
		echo "ITERATION $i - $CURRENT"
		echo ""

		CSV=data/with-$CURRENT.csv
		NAME=$i-$CURRENT.log
		./run.sh $SLS $CURRENT > $DIR/logs/$NAME
		grep "Time: " $DIR/logs/$NAME | cut -f 2 -w - >> $CSV
		CURRENT=$(($CURRENT + $STEP))
	done
done

rm /*.sls

