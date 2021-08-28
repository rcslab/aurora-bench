#!/usr/local/bin/bash

. helpers/util.sh

export LC_ALL=C.UTF-8
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib"

PILLOWDIR="dependencies/pillow-perf"
MOSHTMP="/tmp/moshtmp"
SLEEPTIME="2"
TMPCKPT="/tmp/ckpt"
TMPREST="/tmp/rest"
OID="4545"
export MNT=/testmnt

getrss() {
	ps -o rss,pid | grep $1 | cut -d " " -f 1
}


setup() {
	mount -t fdescfs fdesc /dev/fd
	mount -t procfs proc /proc
}

checkpoint_aurora() {
	$SLSCTL checkpoint -o "$OID" -r
}
restore_aurora() {
	$SLSCTL restore -o "$OID" -s
}

teardown() {
	umount /dev/fd >/dev/null 2>/dev/null
	umount /proc >/dev/null 2>/dev/null
}

base_checkpoint_restore()
{
	PID=$1
	NAME=$2
	BACKEND=$3
	IS_DELTA=$4

	if [ $IS_DELTA == "yes" ]; then
	    $SLSCTL partadd -o "$OID" -l -b $BACKEND
	else 
	    $SLSCTL partadd -o "$OID" -d -b $BACKEND
	fi

	$SLSCTL attach -o "$OID" -p "$PID"

	if [ $IS_DELTA == "yes" ]; then
	    checkpoint_aurora
	    sleep $SLEEPTIME
	fi

	$SRCROOT/scripts/ckpt.d > $TMPCKPT 2> $TMPCKPT &
	sleep $SLEEPTIME

	checkpoint_aurora
	sleep $SLEEPTIME
	sleep 5

	pkill -SIGTERM dtrace 
	pkill -SIGTERM $NAME  >/dev/null 2>/dev/null
	kill -SIGTERM $PID > /dev/null 2>/dev/null
	sleep 2
	$SRCROOT/scripts/rest.d > $TMPREST 2> $TMPREST &
	sleep $SLEEPTIME
	NS=`cat $TMPCKPT | grep "Application stop time" | rev | cut -w -f 1 | rev | tr -d '\n'`
	printf "$NS ns\t"	
	rm $TMPCKPT

	restore_aurora &
	sleep $SLEEPTIME

	pkill -SIGTERM dtrace
	sleep $SLEEPTIME 
	NS=`cat $TMPREST | grep "Total time" | rev | cut -w -f 2 | rev | tr -d '\n'`
	printf "$NS ns\t"	
	rm $TMPREST

	teardown_aurora >/dev/null 2>/dev/null
}


memory_checkpoint_memory_restore()
{
	PID=$1
	NAME=$2

	base_checkpoint_restore $PID $NAME memory no
}

full_checkpoint_full_restore()
{
	PID=$1
	NAME=$2

	base_checkpoint_restore $PID $NAME slos no
}

delta_checkpoint_lazy_restore()
{
	PID=$1
	NAME=$2

	base_checkpoint_restore $PID $NAME slos yes
}

run_firefox() {
	teardown_aurora
	setup_aurora
	./dlroot.sh >/dev/null 2>/dev/null
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib" chroot $MNT firefox -headless -createprofile artifact  >/dev/null 2>/dev/null &
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib" chroot $MNT firefox -headless -P artifact >/dev/null 2>/dev/null &
	sleep $SLEEPTIME
}

test_firefox() {
    printf "firefox\t"
    run_firefox
    PID=`ps | grep " firefox" | grep -v grep | cut -w -f 1`
    memory_checkpoint_memory_restore $PID "firefox"

    run_firefox 
    PID=`ps | grep " firefox" | grep -v grep | cut -w -f 1`
    full_checkpoint_full_restore	$PID "firefox"

    run_firefox 
    PID=`ps | grep " firefox" | grep -v grep | cut -w -f 1`
    delta_checkpoint_lazy_restore	$PID "firefox"
    printf "\n"
}

run_mosh() {
	teardown_aurora
	setup_aurora
	./dlroot.sh >/dev/null 2>/dev/null
	LANG=C.UTF-8 chroot $MNT mosh-server >$MOSHTMP 2> $MOSHTMP &
	sleep $SLEEPTIME
}

test_mosh() {
	printf "mosh\t"
	run_mosh
	PID=`sed -n 's/\[mosh-server detached, pid = \([0-9]*\)\]/\1/p' $MOSHTMP` 
	memory_checkpoint_memory_restore    $PID "mosh-server"
	rm $MOSHTMP

	run_mosh
	PID=`sed -n 's/\[mosh-server detached, pid = \([0-9]*\)\]/\1/p' $MOSHTMP` 
	full_checkpoint_full_restore	    $PID "mosh-server"
	rm $MOSHTMP

	run_mosh
	PID=`sed -n 's/\[mosh-server detached, pid = \([0-9]*\)\]/\1/p' $MOSHTMP` 
	rm $MOSHTMP
	delta_checkpoint_lazy_restore	    $PID "mosh-server"
	printf "\n"
}

run_pillow() {
	teardown_aurora
	setup_aurora
	./dlroot.sh >/dev/null 2>/dev/null
	cp -r $PILLOWDIR $MNT/root/
	chroot $MNT /root/pillow-perf/testsuite/run.py --runs 10000 scale > /dev/null 2> /dev/null &
	sleep $SLEEPTIME
}

test_pillow() {
    printf "pillow\t"
    run_pillow 
    memory_checkpoint_memory_restore	`pidof python3.7` "python3.7"

    run_pillow 
    full_checkpoint_full_restore	`pidof python3.7` "python3.7"

    run_pillow 
    delta_checkpoint_lazy_restore	`pidof python3.7` "python3.7"
    printf "\n"
}

run_tomcat() {
	teardown_aurora
	setup_aurora
	./dlroot.sh >/dev/null 2>/dev/null
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib" JRE_HOME="/usr/local/openjdk8" chroot $MNT /usr/local/apache-tomcat-9.0/bin/startup.sh >/dev/null 2>/dev/null & 
	sleep $SLEEPTIME
}

test_tomcat() {
    printf "tomcat\t"
    run_tomcat 
    memory_checkpoint_memory_restore	`pidof java` "java"

    run_tomcat 
    full_checkpoint_full_restore	`pidof java` "java"

    run_tomcat
    delta_checkpoint_lazy_restore	`pidof java` "java"
    printf "\n"
}

run_vim() {
	teardown_aurora
	setup_aurora
	./dlroot.sh >/dev/null 2>/dev/null
	LD_LIBRARY_PATH="$LD_LIBRARY_PATH:/usr/local/lib" chroot $MNT tmux new-session -d 'vim -c stop' >/dev/null 2>/dev/null
	sleep $SLEEPTIME
}

test_vim() {
    printf "vim\t"
    run_vim 
    memory_checkpoint_memory_restore	`pidof vim` "vim"

    run_vim 
    full_checkpoint_full_restore	`pidof vim` "vim"

    run_vim
    delta_checkpoint_lazy_restore	`pidof vim` "vim"
    printf "\n"
}

setup_script
setup_aurora

printf "Name\tMemory Ckpt\tMemory Restore\tFull Ckpt\tFull Restore\tIncremental Ckpt\tLazy Restore\n"
test_vim
test_mosh
test_pillow 
test_tomcat
test_firefox
teardown_aurora
