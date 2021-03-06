#!/usr/local/bin/bash
. aurora.config

YCSB_TAR="https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz"
THRS=`sysctl hw.ncpu | awk -F ' ' '{print $2}'`
setup_filebench()
{
    # Setup filebench
    git clone https://github.com/krhancoc/filebench.git dependencies/filebench
    cd dependencies/filebench

    # Configure filebench
    libtoolize
    aclocal
    autoheader
    automake --add-missing
    autoconf

    # Make Filebench
    ./configure
    make -j $THRS
    make install
    cd -
}

setup_pillow_perf()
{
    git clone https://github.com/python-pillow/pillow-perf.git dependencies/pillow-perf
}

setup_mutilate()
{
    echo "[Aurora] Setting up mutilate"
    git clone https://github.com/rcslab/mutilate.git dependencies/mutilate
    cd dependencies/mutilate

    set -- $ALL_HOSTS
    while [ -n "$1" ];
    do
	echo "[Aurora] Setting up Client $1"
	ssh $1 "cd $AURORA_CLIENT_DIR; git clone https://github.com/rcslab/mutilate.git; cd mutilate; scons" > /dev/null 2> /dev/null
	shift
    done

    echo "[Aurora] Setting up Host"
    scons > /dev/null 2> /dev/null
    cd -
}


setup_dsmb()
{
    echo "[Aurora] Setting up DSMB"
    echo "COMMAND IS $COMPILE_DSMB"

    # One-liner because we need to run it on the remote host, too.
    COMPILE_DSMB="git clone https://github.com/rcslab/dsmb.git; mkdir dsmb/build; cd dsmb/build; cmake ..; make -j9"

    # Download DSMB on the server since we need PPD.
    PREVIOUS_PWD=`pwd`
    cd dependencies; git clone https://github.com/rcslab/dsmb.git; mkdir dsmb/build; cd dsmb/build; cmake ..; make
    cd $PREVIOUS_PWD

    # Download DSMB on each host
    set -- $ALL_HOSTS
    while [ -n "$1" ];
    do
	echo "[Aurora] Setting up Client $1"
	ssh $1 "cd $AURORA_CLIENT_DIR; git clone https://github.com/rcslab/dsmb.git; mkdir dsmb/build; cd dsmb/build; cmake ..; make" > /dev/null 2> /dev/null
	shift
    done

    echo "[Aurora] Setting up Host"
    scons > /dev/null 2> /dev/null
    cd -
}



setup_ycsb()
{
    # Setup YCSB
    echo "[Aurora] Setting up YCSB"
    PD=$(pwd)
    cd dependencies
    curl -O --location $YCSB_TAR
    tar -zxvf ycsb-0.17.0.tar.gz > /dev/null 2> /dev/null

    set -- $ALL_HOSTS
    while [ -n "$1" ];
    do
	echo "[Aurora] Setting up Client $1"
	ssh $1 "cd $AURORA_CLIENT_DIR; curl -O --location $YCSB_TAR; tar -zxvf ycsb-0.17.0.tar.gz"
	shift
    done

    cd $PD
}

setup_prog()
{
    echo "[Aurora] Setting up graphing tool progbg"
    git clone --branch artifact https://github.com/krhancoc/progbg.git dependencies/progbg
    pkg install -y py37-numpy py37-matplotlib py37-pandas py37-flask
    chmod -R a+rw dependencies/progbg
}

check_library()
{
    O1=`ls /usr/local/lib | grep $1`
    O2=`ls /usr/lib | grep $1`
    O3=`ls /lib | grep $1`
    if [ -z "$O1" ] && [ -z "$O2" ] && [ -z "$O3" ]; then
	echo "Library $1 not present locally, please install"
    fi

}

check_remote_library()
{
    O1=`ssh $2 ls /usr/local/lib | grep $1`
    O2=`ssh $2 ls /usr/lib | grep $1`
    O3=`ssh $2 ls /lib | grep $1`
    if [ -z "$O1" ] && [ -z "$O2" ] && [ -z "$O3" ]; then
	echo "Library $1 not present on remote $2, please install"
    fi
}

check_binary()
{
    BIN_VAR=`which $1`
    if [ -z $BIN_VAR ]; then
	echo "Binary $1 not present locally, please install"
	exit 1
    else
	return
    fi
}

check_remote_binary()
{
    LIB=$1
    HOST=$2
    BIN_VAR=`ssh $2 "which $1"`
    if [ -z $BIN_VAR ]; then
	echo "Binary $1 not present on host($HOST), please install"
	exit 1
    else
	return
    fi
}

check_scons_versions()
{
    local=`scons -v | grep -E -w 'python3.7|python3.8'`
    if [[ ! $local ]]; then
	echo "Scons must be using version python3.7 or higher"
    fi

    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	local=`ssh $1 scons -v | grep -E -w 'python3.7|python3.8'`
	if [[ ! $local ]]; then
	    echo "Scons must be using version python3.7 or higher"
	fi
	shift
    done

}

check_dependencies()
{
    # Dependencies to build filebench
    check_binary "libtoolize"
    check_binary "aclocal"
    check_binary "autoheader"
    check_binary "automake"
    check_binary "autoconf"
    check_binary "cmake"

    # Dependencies for redis
    check_binary "redis-server"
    check_binary "javac"

    # Dependencies for memcached
    check_binary "scons"
    check_binary "gengetopt"
    check_binary "memcached"

    # Dependencies for rocksdb
    check_library "snappy"
    check_library "gflags"
    check_library "libzmq.so.1" $1 # Required to compile mutilate

    set -- $EXTERNAL_HOSTS
    while [ -n "$1" ];
    do
	check_remote_binary "scons" $1
	check_remote_library "libzmq.so.1" $1 # Required to compile mutilate
	check_remote_binary "gengetopt" $1 # Required to compile mutilate
	check_remote_binary "javac" $1 # Required for redis to run ycsb
	shift
    done

    check_scons_versions
}

setup_rocksdb()
{
    PD=$(pwd)
    git clone https://github.com/rcslab/aurora-rocksdb.git dependencies/rocksdb
    cd dependencies/rocksdb

    git checkout sls-baseline2
    mkdir baseline
    cd baseline
    cmake .. -DCMAKE_BUILD_TYPE=Release -DFAIL_ON_WARNINGS=OFF -DWITH_SNAPPY=ON -DSLS_PATH=$SRCROOT
    make -j $THRS db_bench

    cd ..
    git checkout sls2
    mkdir sls
    cd sls
    cmake .. -DCMAKE_BUILD_TYPE=Release -DFAIL_ON_WARNINGS=OFF -DWITH_SNAPPY=ON -DSLS_PATH=$SRCROOT
    make -j $THRS db_bench

    cd $PD
}

# Checks all dependencies needed on clients and main aurora host
check_dependencies

mkdir -p $MNT

# Setup SLS Module
cd $SRCROOT
make clean > /dev/null
make -j $THRS > /dev/null
cd -

mkdir dependencies 2> /dev/null
chmod a+rw dependencies

mkdir -p "$AURORA_REDIS_DIR" 2> /dev/null
chmod a+rw "$AURORA_REDIS_DIR" 2> /dev/null

mkdir $OUT 2> /dev/null
chmod a+rw $OUT 2> /dev/null


# Fetches and unpacks ycsb artifact
echo "[Aurora] Setting up YCSB"
setup_ycsb > /dev/null 2> /dev/null

# Fetches and compiles filebench
echo "[Aurora] Setting up filebench"
setup_filebench > /dev/null

# Sets up the python library used to create graphs
echo "[Aurora] Setting up progbg"
setup_prog > /dev/null

# Grabs the Pillow performance suite
echo "[Aurora] Setting up pillow-perf"
setup_pillow_perf > /dev/null

# Fetches and compiled mutilate on host and all clients
echo "[Aurora] Setting up mutilate"
setup_mutilate  > /dev/null

echo "[Aurora] Setting up rocksdb"
setup_rocksdb > /dev/null

echo "[Aurora] Setting up DSMB"
setup_dsmb > /dev/null

wait
echo "[Aurora] Setup Done"
