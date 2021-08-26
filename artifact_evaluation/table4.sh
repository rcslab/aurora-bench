#!/usr/local/bin/bash

. helpers/util.sh
. aurora.config

sysctl kern.ipc.shm_use_phys=1
cleanup()
{
    pkill posix.d dtrace
    sleep 1
    teardown_aurora > /dev/null 2> /dev/null
}

run_posix() {
    DIR=$OUT/posix
    mkdir -p $DIR
    cleanup
    for ITER in `seq 0 $MAX_ITER`
    do
	    echo "[Aurora] Running Posix: Iteration $ITER"
	    setup_aurora
	    $SRCROOT/scripts/posix.d > /tmp/out 2> /tmp/out &
	    sleep 1
	    $SRCROOT/tests/posix/posix 1 $MNT
	    sleep 2
	    $SRCROOT/tools/slsctl/slsctl restore -o 1
	    sleep 2

	    cleanup
	    mv /tmp/out $DIR/$ITER.out
    done

    cp $DIR/0.out graphs/table4.txt
}

MAX_ITER=0

setup_script
run_posix




