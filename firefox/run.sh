cd hosted
$(python -m http.server) &
cd ..

MAIN_DIR=/usr/home/ryan/sls
kldload $MAIN_DIR/kmod/sls.ko
cp -f $MAIN_DIR/tools/slsctl/slsctl .

FREQ=5000
OPTIONS_WITH="--sls -t $FREQ --single-process"
OPTIONS_WITHOUT="--single-process"
PMCFLAGS="-P itlb_misses.walk_completed -P dtlb_store_misses.walk_completed -P dtlb_load_misses.walk_completed" 

#echo "STARTING WITHOUT SLS"
#$(/usr/bin/time -l -o without.log python benchmark.py $OPTIONS_WITHOUT >> time.log) &
#PID=$(ps | grep "[p]ython benchmark.py" | grep -v "time" | awk '{print $1}')
#echo $PID 
#echo "pmcstat $PMCFLAGS -t $PID"
#pmcstat $PMCFLAGS -O without_pmc.log -t $PID

echo "STARTING WITH SLS"
$(/usr/bin/time -l -o with.log python benchmark.py $OPTIONS_WITH >> time.log)
#PID=$(ps | grep "[p]ython benchmark.py" | grep -v "time" | awk '{print $1}')
#echo $PID 
#echo "pmcstat $PMCFLAGS -t $PID"
#pmcstat $PMCFLAGS -O with_pmc.log -t $PID


PID=$(ps | grep "[p]ython -m http.server" | grep -v "time" | awk '{print $1}')
pkill -9 $PID
pkill python
pkill firefox
pkill geckodriver
