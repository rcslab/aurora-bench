#!/usr/local/bin/bash

set -e

cd ~/code

[ -e rocksdb/build/java/librocksdbjni.so ] || (
    cd rocksdb
    git checkout v6.2.2
    rm -rf build
    mkdir build
    cd build

    JAVA_HOME=/usr/local/openjdk8 cmake .. \
             -DCMAKE_BUILD_TYPE=Release \
             -DFAIL_ON_WARNINGS=OFF \
             -DWITH_SNAPPY=ON \
             -DWITH_JNI=ON \
             -DCUSTOM_REPO_URL="https://repo1.maven.org/maven2"
    make -j$(gnproc) rocksdbjni-shared
    ln -s librocksdbjni-shared.so java/librocksdbjni.so
)

SLS_DIR=/mnt/sls/tmp
SLS_DIR=/tmp

SLS_EXEC="$HOME/code/sls/tools/slsctl/slsctl spawn -o 1000 --"
SLS_EXEC=""

(
    # https://github.com/brianfrankcooper/YCSB/wiki/Core-Workloads
    cd YCSB

    rm -rf "$SLS_DIR/ycsb-rocksdb-data"

    echo "======== Load workload A ========" >../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb load rocksdb -s -P workloads/workloada -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true

    echo "======== Run workload A ========" >>../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb run rocksdb -s -P workloads/workloada -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true
    echo "======== Run workload B ========" >>../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb run rocksdb -s -P workloads/workloadb -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true
    echo "======== Run workload C ========" >>../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb run rocksdb -s -P workloads/workloadc -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true
    echo "======== Run workload F ========" >>../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb run rocksdb -s -P workloads/workloadf -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true
    echo "======== Run workload D ========" >>../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb run rocksdb -s -P workloads/workloadd -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true

    rm -rf "$SLS_DIR/ycsb-rocksdb-data"

    echo "======== Load workload E ========" >>../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb load rocksdb -s -P workloads/workloade -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true
    echo "======== Run workload E ========" >>../sls-rocksdb-ycsb.log
    $SLS_EXEC python2 ./bin/ycsb run rocksdb -s -P workloads/workloade -p rocksdb.dir="$SLS_DIR/ycsb-rocksdb-data" -jvm-args "-Djava.library.path=$PWD/../rocksdb/build/java " >>../sls-rocksdb-ycsb.log || true
)
