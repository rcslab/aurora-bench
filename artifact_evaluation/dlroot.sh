#!/usr/local/bin/bash

. aurora.config

BASEURL="https://rcs.uwaterloo.ca/aurora/ftp/base.txz"

echo $MNT "Mount in $MNT"

if [ -z $MNT ]; then
	echo "No mountpoint specified"
	exit 0
fi

if [ ! -f base.txz ]; then
	fetch $BASEURL
fi

tar -C $MNT -xvf base.txz
cp -R -p /usr/local/* $MNT/usr/local/
cp -r /root/sls-bench/artifact_evaluation/dependencies/pillow-perf $MNT/root
