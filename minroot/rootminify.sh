#!/bin/sh

# Script that creates a minimal root for benchmarks

# Import the configuration
. "$BENCHROOT/minroot/minroot"

TMPSRC="/mnt/src"
TMPDST="/mnt/dst"

movefile()
{
    FILE=$1
    if [ -z $FILE ]; then
	return
    fi

    DIR="$(dirname $FILE)"
    if [ ! -z "$DIR" ]; then
	mkdir -p "$TMPDST/$DIR"
    fi
    cp -r "$TMPSRC/$FILE" "$TMPDST/$FILE"
    echo "Moving $FILE"
}

crdir()
{
    DIR=$1
    if [ -z $DIR ]; then
	return
    fi

    mkdir -p "$TMPDST/$DIR"

}

if [ -f "$MINIFIED_ROOTFS" ]; then
    return
fi

mkdir -p "$TMPSRC"
mkdir -p "$TMPDST"

tar -C "$TMPSRC" -xf "$ROOTFS"

movefile /bin
movefile /sbin
movefile /etc
movefile /lib
movefile /libexec
movefile /usr/libexec

crdir data
crdir var
crdir var/cache
crdir var/run
crdir log
crdir logs
crdir dev

# Dependency for Redis not in /lib
movefile /usr/local/bin/redis-server
movefile /usr/lib/libexecinfo.so.1

tar -C "$TMPDST" -czf "$MINIFIED_ROOTFS" .

# Change permissions
chflags -R noschg,nosunlink $TMPSRC
chflags -R noschg,nosunlink $TMPDST
rm -rf $TMPSRC
rm -rf $TMPDST
