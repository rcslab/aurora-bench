bash ycsb_memcached.sh memcached.config mem mem
bash ycsb_memcached.sh memcached.config sls-100 sls 100
bash ycsb_memcached.sh memcached.config sls-500 sls 500
bash ycsb_memcached.sh memcached.config sls-1000 sls 1000
bash ycsb_memcached.sh memcached.config sls-5000 sls 5000

bash ycsb_redis.sh redis.config mem mem
bash ycsb_redis.sh redis.config rdb rdb
bash ycsb_redis.sh redis.config aof aof
bash ycsb_redis.sh redis.config sls-100 sls 100
bash ycsb_redis.sh redis.config sls-500 sls 500
bash ycsb_redis.sh redis.config sls-1000 sls 1000
bash ycsb_redis.sh redis.config sls-5000 sls 5000
