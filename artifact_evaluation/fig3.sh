#!/bin/sh
echo "[Aurora] Figure 3"

. helpers/util.sh
. aurora.config

BENCHMARKS="../fs-workloads/"

run_aurorafs()
{
	echo "[Aurora] Running AuroraFS"
	setup_script

	teardown_aurora > /dev/null 2> /dev/null

	# AuroraFS: Figure 3 
	ROOT_DIR=$OUT/filesystem/aurora
	for folder in "macro" "micro";
	do
	    SUPER=$ROOT_DIR/$folder
	    mkdir -p $SUPER
	    for entry in `ls $BENCHMARKS/$folder/*.f`
	    do
		    FILE=`basename $entry`
		    DIR=$SUPER/$FILE
		    mkdir -p $DIR

		    for ITER in `seq $START $MAX_ITER`
		    do
			    if check_completed $DIR/$ITER.out; then
				continue
			    fi
			    FINAL_OUT="$ITER.out"
			    echo "[Aurora] Running $folder:$FILE, Iteration $ITER"
			    echo "[Aurora] Running $folder:$FILE, Iteration $ITER" >> $LOG
			    setup_aurora  >> $LOG 2>> $LOG

			    timeout 60s $FILEBENCH -f $entry > /tmp/out 2>> $LOG
			    teardown_aurora >> $LOG 2>> $LOG
			    mv /tmp/out $DIR/$FINAL_OUT
		    done
	    done
	done
}

run_ffs()
{
	echo "[Aurora] Running FFS"
	setup_script

	teardown_ffs > /dev/null 2> /dev/null

	# AuroraFS: Figure 3 
	ROOT_DIR=$OUT/filesystem/ffs
	for folder in "macro" "micro";
	do
	    SUPER=$ROOT_DIR/$folder
	    mkdir -p $SUPER

	    for entry in `ls $BENCHMARKS/$folder/*.f`
	    do
		    FILE=`basename $entry`
		    DIR=$SUPER/$FILE
		    mkdir -p $DIR

		    for ITER in `seq 0 $MAX_ITER`
		    do
			    if check_completed $DIR/$ITER.out; then
				continue
			    fi
			    FINAL_OUT="$ITER.out"
			    echo "[Aurora] Running $FILE, Iteration $ITER"
			    echo "[Aurora] Running $FILE, Iteration $ITER">> $LOG

			    setup_ffs >> $LOG 2>> $LOG
			    timeout 60s $FILEBENCH -f $entry > /tmp/out 2>> $LOG 
			    teardown_ffs >> $LOG 2>> $LOG

			    # This is so we catch if it crashes
			    mv /tmp/out $DIR/$FINAL_OUT
		    done
	    done
	done
}

run_zfs()
{
	CHECKSUM=$1
	echo "[Aurora] Running ZFS, checksumming $CHECKSUM"
	setup_script
	teardown_zfs > /dev/null 2> /dev/null

	# AuroraFS: Figure 3 
	ROOT_DIR=$OUT/filesystem/zfs-$CHECKSUM

	for folder in "macro" "micro";
	do
	    SUPER=$ROOT_DIR/$folder
	    mkdir -p $SUPER
	    for entry in `ls $BENCHMARKS/$folder/*.f`
	    do
		    FILE=`basename $entry`
		    DIR=$SUPER/$FILE
		    mkdir -p $DIR

		    for ITER in `seq $START $MAX_ITER`
		    do
			    if check_completed $DIR/$ITER.out; then
				continue
			    fi
			    FINAL_OUT="$ITER.out"
			    echo "[Aurora] Running $FILE, Iteration $ITER"
			    echo "[Aurora] Running $FILE, Iteration $ITER" >> $LOG
			    setup_zfs $CHECKSUM >> $LOG 2>> $LOG
			    timeout 60s $FILEBENCH -f $entry > /tmp/out 2>> $LOG
			    teardown_zfs $CHECKSUM  >> $LOG 2>> $LOG
			    mv /tmp/out $DIR/$FINAL_OUT
		    done
	    done
	done
}


clear_log

run_ffs

run_zfs "off"

run_zfs "on"

run_aurorafs

PYTHONPATH=$PYTHONPATH:$(pwd)/dependencies/progbg
export PYTHONPATH
export OUT
python3.7 -m progbg graphing/fig3.py
