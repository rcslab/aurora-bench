#!/usr/local/bin/bash
SLS=$1
FREQ=$2

cd hosted
$(python -m http.server) &
cd ..


if ! [[ -z "$FREQ" ]]
then
	echo "Running with SLS"
	kldload $SLS/kmod/sls.ko
	cp $SLS/tools/slsctl/slsctl .
	./slsctl
	OPTIONS="--sls -t $FREQ"
	echo $OPTIONS
else
	echo "Running without SLS"
	OPTIONS=""
	echo $OPTIONS
fi
# PMCFLAGS="-P itlb_misses.walk_completed -P dtlb_store_misses.walk_completed -P dtlb_load_misses.walk_completed" 

#/usr/bin/time -l -o with.log 
python benchmark.py $OPTIONS
#PID=$(ps | grep "[p]ython benchmark.py" | grep -v "time" | awk '{print $1}')
#echo $PID 
#echo "pmcstat $PMCFLAGS -t $PID"
#pmcstat $PMCFLAGS -O with_pmc.log -t $PID
#PID=$(ps | grep "[p]ython -m http.server" | grep -v "time" | awk '{print $1}')

echo "Clean up"
if ! [[ -z "$FREQ" ]]
then
	kldunload sls.ko
	rm slsctl
fi
pkill python
pkill firefox
pkill geckodriver
