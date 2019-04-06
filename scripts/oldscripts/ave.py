import sys
import numpy

i = 0
data = [[] for i in range(18)]

header = ["PING_INLINE","PING_BULK","SET","GET","INCR","LPUSH","RPUSH","LPOP",
        "RPOP","SADD","HSET","SPOP","LPUSH","LRANGE_100","LRANGE_300",
        "LRANGE_500","LRANGE_600","MSET"]
for line in sys.stdin:
    data[i].append(float(line.split(":")[1]))
    i = (i + 1) % 18


for i in range(18):
    #top = max(data[i])
    #bot = min(data[i])
    #for j in range(len(data[i])):
    #    data[i][j] = (data[i][j] - bot) / (top - bot)
    #print(data[i])
    print("%s\t%.2f\t%.2f" % (header[i],sum(data[i])/len(data[i]),
        numpy.std(data[i])))
