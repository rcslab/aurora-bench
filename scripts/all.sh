kldload $1/kmod/sls.ko

bash redis-exp.sh $2 mem redis 100000 redisexp/redis-mem
bash redis-exp.sh $2 rdb redis 100000 redisexp/redis-rdb
bash redis-exp.sh $2 aof redis 100000 redisexp/redis-aof
bash redis-exp.sh $2 sls 1000 50 redis 100000 redisexp/redis-sls-1000
bash redis-exp.sh $2 sls 100 500 redis 100000 redisexp/redis-sls-100
bash redis-exp.sh $2 mem ycsb ycsb_wkld/heavy redisexp/heavy-mem
bash redis-exp.sh $2 rdb ycsb ycsb_wkld/heavy redisexp/heavy-rdb
bash redis-exp.sh $2 aof ycsb ycsb_wkld/heavy redisexp/heavy-aof
bash redis-exp.sh $2 sls 1000 50 ycsb ycsb_wkld/heavy redisexp/heavy-sls-1000
bash redis-exp.sh $2 sls 100 500 ycsb ycsb_wkld/heavy redisexp/heavy-sls-100
grep "Throughput" -R redisexp/heavy-mem-* | awk '{print $3}' | python3 meanstd.py > heavy-mem.sum
grep "Throughput" -R redisexp/heavy-rdb-* | awk '{print $3}' | python3 meanstd.py > heavy-rdb.sum
grep "Throughput" -R redisexp/heavy-aof-* | awk '{print $3}' | python3 meanstd.py > heavy-aof.sum
grep "Throughput" -R redisexp/heavy-sls-1000-* | awk '{print $3}' | python3 meanstd.py > heavy-sls-1000.sum
grep "Throughput" -R redisexp/heavy-sls-100-* | awk '{print $3}' | python3 meanstd.py > heavy-sls-100.sum
bash redis-exp.sh $2 mem ycsb ycsb_wkld/latest redisexp/latest-mem
bash redis-exp.sh $2 rdb ycsb ycsb_wkld/latest redisexp/latest-rdb
bash redis-exp.sh $2 aof ycsb ycsb_wkld/latest redisexp/latest-aof
bash redis-exp.sh $2 sls 1000 50 ycsb ycsb_wkld/latest redisexp/latest-sls-1000
bash redis-exp.sh $2 sls 100 500 ycsb ycsb_wkld/latest redisexp/latest-sls-100
grep "Throughput" -R redisexp/latest-mem-* | awk '{print $3}' | python3 meanstd.py > latest-mem.sum
grep "Throughput" -R redisexp/latest-rdb-* | awk '{print $3}' | python3 meanstd.py > latest-rdb.sum
grep "Throughput" -R redisexp/latest-aof-* | awk '{print $3}' | python3 meanstd.py > latest-aof.sum
grep "Throughput" -R redisexp/latest-sls-1000-* | awk '{print $3}' | python3 meanstd.py > latest-sls-1000.sum
grep "Throughput" -R redisexp/latest-sls-100-* | awk '{print $3}' | python3 meanstd.py > latest-sls-100.sum
bash redis-exp.sh $2 mem ycsb ycsb_wkld/mostread redisexp/mostread-mem
bash redis-exp.sh $2 rdb ycsb ycsb_wkld/mostread redisexp/mostread-rdb
bash redis-exp.sh $2 aof ycsb ycsb_wkld/mostread redisexp/mostread-aof
bash redis-exp.sh $2 sls 1000 50 ycsb ycsb_wkld/mostread redisexp/mostread-sls-1000
bash redis-exp.sh $2 sls 100 500 ycsb ycsb_wkld/mostread redisexp/mostread-sls-100
grep "Throughput" -R redisexp/mostread-mem-* | awk '{print $3}' | python3 meanstd.py > mostread-mem.sum
grep "Throughput" -R redisexp/mostread-rdb-* | awk '{print $3}' | python3 meanstd.py > mostread-rdb.sum
grep "Throughput" -R redisexp/mostread-aof-* | awk '{print $3}' | python3 meanstd.py > mostread-aof.sum
grep "Throughput" -R redisexp/mostread-sls-1000-* | awk '{print $3}' | python3 meanstd.py > mostread-sls-1000.sum
grep "Throughput" -R redisexp/mostread-sls-100-* | awk '{print $3}' | python3 meanstd.py > mostread-sls-100.sum
bash redis-exp.sh $2 mem ycsb ycsb_wkld/onlyread redisexp/onlyread-mem
bash redis-exp.sh $2 rdb ycsb ycsb_wkld/onlyread redisexp/onlyread-rdb
bash redis-exp.sh $2 aof ycsb ycsb_wkld/onlyread redisexp/onlyread-aof
bash redis-exp.sh $2 sls 1000 50 ycsb ycsb_wkld/onlyread redisexp/onlyread-sls-1000
bash redis-exp.sh $2 sls 100 500 ycsb ycsb_wkld/onlyread redisexp/onlyread-sls-100
grep "Throughput" -R redisexp/onlyread-mem-* | awk '{print $3}' | python3 meanstd.py > onlyread-mem.sum
grep "Throughput" -R redisexp/onlyread-rdb-* | awk '{print $3}' | python3 meanstd.py > onlyread-rdb.sum
grep "Throughput" -R redisexp/onlyread-aof-* | awk '{print $3}' | python3 meanstd.py > onlyread-aof.sum
grep "Throughput" -R redisexp/onlyread-sls-1000-* | awk '{print $3}' | python3 meanstd.py > onlyread-sls-1000.sum
grep "Throughput" -R redisexp/onlyread-sls-100-* | awk '{print $3}' | python3 meanstd.py > onlyread-sls-100.sum
#
bash redis-exp.sh $2 mem ycsb ycsb_wkld/rmw redisexp/rmw-mem
bash redis-exp.sh $2 rdb ycsb ycsb_wkld/rmw redisexp/rmw-rdb
bash redis-exp.sh $2 aof ycsb ycsb_wkld/rmw redisexp/rmw-aof
bash redis-exp.sh $2 sls 1000 50 ycsb ycsb_wkld/rmw redisexp/rmw-sls-1000
bash redis-exp.sh $2 sls 100 500 ycsb ycsb_wkld/rmw redisexp/rmw-sls-100
grep "Throughput" -R redisexp/rmw-mem-* | awk '{print $3}' | python3 meanstd.py > rmw-mem.sum
grep "Throughput" -R redisexp/rmw-rdb-* | awk '{print $3}' | python3 meanstd.py > rmw-rdb.sum
grep "Throughput" -R redisexp/rmw-aof-* | awk '{print $3}' | python3 meanstd.py > rmw-aof.sum
grep "Throughput" -R redisexp/rmw-sls-1000-* | awk '{print $3}' | python3 meanstd.py > rmw-sls-1000.sum
grep "Throughput" -R redisexp/rmw-sls-100-* | awk '{print $3}' | python3 meanstd.py > rmw-sls-100.sum
#
bash redis-exp.sh $2 mem ycsb ycsb_wkld/short redisexp/short-mem
bash redis-exp.sh $2 rdb ycsb ycsb_wkld/short redisexp/short-rdb
bash redis-exp.sh $2 aof ycsb ycsb_wkld/short redisexp/short-aof
bash redis-exp.sh $2 sls 1000 50 ycsb ycsb_wkld/short redisexp/short-sls-1000
bash redis-exp.sh $2 sls 100 500 ycsb ycsb_wkld/short redisexp/short-sls-100
grep "Throughput" -R redisexp/short-mem-* | awk '{print $3}' | python3 meanstd.py > short-mem.sum
grep "Throughput" -R redisexp/short-rdb-* | awk '{print $3}' | python3 meanstd.py > short-rdb.sum
grep "Throughput" -R redisexp/short-aof-* | awk '{print $3}' | python3 meanstd.py > short-aof.sum
grep "Throughput" -R redisexp/short-sls-1000-* | awk '{print $3}' | python3 meanstd.py > short-sls-1000.sum
grep "Throughput" -R redisexp/short-sls-100-* | awk '{print $3}' | python3 meanstd.py > short-sls-100.sum

kldunload sls.ko
#
