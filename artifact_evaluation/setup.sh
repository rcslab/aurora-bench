#!/usr/local/bin/bash
. aurora.config

YCSB_TAR="https://github.com/brianfrankcooper/YCSB/releases/download/0.17.0/ycsb-0.17.0.tar.gz"
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
    make -j 8
    make install
    cd -
}

setup_mutilate()
{
    # Setup filebench
    git clone https://github.com/rcslab/mutilate.git dependencies/mutilate
    cd dependencies/mutilate

    set -- $EXTERNAL_HOSTS
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


setup_ycsb()
{
    # Setup YCSB
    PD=$(pwd)
    cd dependencies
    curl -O --location $YCSB_TAR
    tar -zxvf ycsb-0.17.0.tar.gz > /dev/null 2> /dev/null

    set -- $EXTERNAL_HOSTS
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
    git clone --branch artifact https://github.com/krhancoc/progbg.git dependencies/progbg
    pkg install -y py37-numpy py37-matplotlib py37-pandas py37-flask
    chmod -R a+rw dependencies/progbg
}

check_library()
{
    O1=`ls /usr/local/lib | grep $1`
    O2=`ls /usr/lib | grep $1`
    O3=`ls /lib | grep $1`
    echo "$O1 $O2 $O3"
    if [ -z $O1 ] && [ -z $O2 ] && [ -z $O3 ]; then
	echo "Libary $1 not present locally, please install"
    fi

}

check_remote_library()
{
    O1=`ssh $2 ls /usr/local/lib | grep $1`
    O3=`ssh $2 ls /usr/lib | grep $1`
    O3=`ssh $2 ls /lib | grep $1`
    if [ -z $O1 ] && [ -z $O2 ] && [ -z $O3 ]; then
	echo "Libary $1 not present on remote $2, please install"
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
    # Depedencies for clients

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
    git clone https://github.com/krhancoc/rocksdb.git dependencies/rocksdb
    cd dependencies/rocksdb

    git checkout sls-baseline2
    mkdir baseline
    cd baseline
    cmake .. -DCMAKE_BUILD_TYPE=Release -DFAIL_ON_WARNINGS=OFF -DWITH_SNAPPY=ON -DSLS_PATH=$SRCROOT
    make -j 32 db_bench

    cd ..
    git checkout sls2
    mkdir sls
    cd sls
    cmake .. -DCMAKE_BUILD_TYPE=Release -DFAIL_ON_WARNINGS=OFF -DWITH_SNAPPY=ON -DSLS_PATH=$SRCROOT
    make -j 32 db_bench

    cd $PD
}

mkdir dependencies 2> /dev/null
chmod a+rw dependencies

mkdir -p "$AURORA_REDIS_DIR" 2> /dev/null
chmod a+rw "$AURORA_REDIS_DIR" 2> /dev/null

mkdir $OUT 2> /dev/null
chmod a+rw $OUT 2> /dev/null

# Checks all dependencies needed on clients and main aurora host
check_dependencies

# Fetches and unpacks ycsb artifact
setup_ycsb > /dev/null

# Fetches and compiles filebench
setup_filebench > /dev/null

# Sets up the python library used to create graphs
setup_prog > /dev/null

# Fetches and compiled mutilate on host and all clients
setup_mutilate  > /dev/null

setup_rocksdb > /dev/null

wait
