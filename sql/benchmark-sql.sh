#!/usr/local/bin/bash

SQL=$1
SLS=$2
ITER="$3"
MIN="$4"
MAX="$5"
STEP="$6"

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
	./run.sh $SQL $SLS > $DIR/logs/$NAME
	grep "transactions: " $DIR/logs/$NAME | cut -f 4 -w - | cut -b 2- - >> $CSV
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
		./run.sh $SQL $SLS $CURRENT > $DIR/logs/$NAME
		grep "transactions: " $DIR/logs/$NAME | cut -f 4 -w - | cut -b 2- - >> $CSV
		CURRENT=$(($CURRENT + $STEP))
	done
done

