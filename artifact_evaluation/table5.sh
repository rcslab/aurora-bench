#!/usr/bin/env bash

. helpers/util.sh
. aurora.config

# Disk devices for the devices used 
# Execute one iteration of the atomic memory region 
# checkpointing microbenchmark.
atomic_iterate() {
    # Set up Aurora and wait for it to be initialized.
    setup_aurora > /dev/null 2>/dev/null
    sleep 1
    
    $SRCROOT/tests/vmregion/vmregion $1

    # Wait for the system to quiesce and tear down Aurora.
    sleep 2
    teardown_aurora > /dev/null 2> /dev/null
}

# Execute one iteration of the incremental
# application checkpointing microbenchmark
incremental_iterate() {
    # Same structure as atomic_iterate().
    setup_aurora > /dev/null 2>/dev/null
    sleep 1

    $SRCROOT/tests/vmobject/vmobject 1 $1

    sleep 2
    teardown_aurora > /dev/null 2> /dev/null
}

# Execute one iteration of the journaled
# persistence microbenchmark.
journal_iterate() {
    # Same structure as atomic_iterate().
    sleep 1

    $SETUP_FUNC > /dev/null 2> /dev/null
    # Create one VM object (i.e. mapped set of pages)
    # with the size given.
    $SRCROOT/tests/journal/journal $DISKPATH $1

    $TEARDOWN_FUNC $DISKPATH > /dev/null 2> /dev/null
    sleep 2
}

print_size() {
    POWER=$1
    SIZE=$2

    if [ $POWER -lt 20 ]; then
	printf "$(( SIZE / 1024 ))kiB"
    elif [ $POWER -lt 30 ]; then
	printf "$(( SIZE / (1024 * 1024)))MiB"
    else
	printf "$(( SIZE / (1024 * 1024 * 1024)))GiB"
    fi
    printf "\t\t"
}

setup_script

DIR=graphs/table5.txt

printf "Table 4\n" > $DIR
printf "=======\n\n" >> $DIR
printf "SIZE(Bytes)\tINCREMENTAL\tATOMIC\tJOURNAL\n" >> $DIR
# Execute the microbenchmarks for sizes starting from
# 4kiB (2 ^ 12 bytes)  to 1GiB (2 ^ 30 bytes), quadrupling 
# (2 ^ 2) the size on each iteration.
for POWER  in `seq 12 2 30`; do
    SIZE=$((2 ** $POWER))
    print_size $POWER $SIZE >> $DIR
    printf `atomic_iterate $SIZE | cut -w -f 3 ` >> $DIR
    printf "\t\t" >> $DIR
    printf `incremental_iterate $SIZE | cut -w -f 4` >> $DIR
    printf "\t" >> $DIR
    printf `journal_iterate $SIZE` >> $DIR
    printf "\n " >> $DIR
    echo "[Aurora] Done objects of size $(print_size $POWER $SIZE)"
done


echo "[Aurora] Done, table also found at $(pwd)/$DIR"
cat $DIR
