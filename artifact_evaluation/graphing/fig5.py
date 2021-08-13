import progbg as sb
import progbg.graphing as g
import progbg.formatters as f
import os

ROOT_DIR=os.environ["OUT"]

fs = ["base-wal", "base-nowal", "aurora-wal", "aurora-nowal"]

def parse(metrics, path):
    with open(path) as f:
        lines = f.readlines()
        found = False
        for i, l in enumerate(lines):
            if "Microseconds per write" in l:
                tmp = lines[i+1:i+4]
                
                avg = float(tmp[0].strip().split()[3])
                nine = float(tmp[2].strip().split()[6])
                ninenine = float(tmp[2].strip().split()[8])

                metrics.add_metric("avg", avg)
                metrics.add_metric("99", nine)
                metrics.add_metric("99.9", ninenine)
                found = True
            if "mixgraph" in l:
                metrics.add_metric("ops", int(l.strip().split()[4]))
            # if "fillbatch" in l:
                # metrics.add_metric("ops", int(l.strip().split()[4]))
        if found == False:
            print("[Error] {} did not execute or pre-emptively shut down, please re-run fig5.sh".format(path))
            print(open(path).read())
            os.unlink(path)
            exit (0)

    
executions = {}
for f in fs:
    path = os.path.join(ROOT_DIR, "rocksdb", f)
    executions[f] = sb.plan_parse(path, path, parse)

bnw = executions["base-nowal"]
anw = executions["aurora-nowal"]

bw = executions["base-wal"]
aw = executions["aurora-wal"]

def rocks_graph(ax, data):
    print(ax)
    print(data)

# Temporary graphs for now
rocks = g.Bar(bnw, ["ops"], label="RocksDB")
rockswal = g.Bar(bw, ["ops"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["ops"], label="Aurora-100Hz")
aurorawal = g.Bar(aw, ["ops"], label="Aurora+WAL")
g1 = sb.plan_graph(g.BarGraph([aurora, rocks, aurorawal, rockswal], out="fig5a.svg"))

rocks = g.Bar(bnw, ["99"], label="RocksDB")
rockswal = g.Bar(bw, ["99"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["99"], label="Aurora-100Hz")
aurorawal = g.Bar(aw, ["99"], label="Aurora+WAL")
g1 = sb.plan_graph(g.BarGraph([aurora, rocks, aurorawal, rockswal], out="fig5b.svg"))

rocks = g.Bar(bnw, ["99.9"], label="RocksDB")
rockswal = g.Bar(bw, ["99.9"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["99.9"], label="Aurora-100Hz")
aurorawal = g.Bar(aw, ["99.9"], label="Aurora+WAL")
g1 = sb.plan_graph(g.BarGraph([aurora, rocks, aurorawal, rockswal], out="fig5c.svg"))

#b2 = g.BarGroup([zfsoff, zfson, ffs, aurora], "operations_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])

