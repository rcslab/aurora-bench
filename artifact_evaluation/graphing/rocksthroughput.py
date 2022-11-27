import progbg as sb
import progbg.graphing as g
import progbg.formatters as format
import os

ROOT_DIR="/home/etsal/aurora-data"

fs = ["base-wal", "base-nowal", "aurora-wal", "aurora-nowal"]

def parse(metrics, path):
    with open(path) as f:
        lines = f.readlines()
        found = False
        for i, l in enumerate(lines):
            if "Microseconds per write" in l:
                if found:
                    tmp = lines[i+1:i+4]
                    
                    avg = float(tmp[0].strip().split()[3])
                    nine = float(tmp[2].strip().split()[6])
                    ninenine = float(tmp[2].strip().split()[8])

                    metrics.add_metric("avg", avg)
                    metrics.add_metric("99", nine)
                    metrics.add_metric("99.9", ninenine)
                else:
                    found = True
            if "mixgraph" in l:
                metrics.add_metric("ops", int(l.strip().split()[4]))
            # if "fillbatch" in l:
                # metrics.add_metric("ops", int(l.strip().split()[4]))
        if found == False:
            print("[Error] {} did not execute or pre-emptively shut down, please re-run fig5.sh".format(path))
            os.unlink(path)


    
executions = {}
for f in fs:
    path = os.path.join(ROOT_DIR, "rocksdb", f)
    executions[f] = sb.plan_parse(path, path, parse)

bnw = executions["base-nowal"]
anw = executions["aurora-nowal"]

bw = executions["base-wal"]
aw = executions["aurora-wal"]

def rocks_graph(ax, data, Operations):
    rows = [ (x.iloc[0].index.tolist()[0], x.iat[0, 0]) for x in data ]
    rows_std = [ (x.iloc[0].index.tolist()[0], x.iat[1, 0]) for x in data ]
    names, values = zip(*rows)
    _, values_std = zip(*rows_std)
    locations = [0, 0.5, 1.5, 2]
    colors = ["#0050ff", "#466225", "#73c2fb", "#99ee90"]
    for i, x in enumerate(values):
        ax.bar(locations[i], [ x ], 0.5, label=names[i], color = colors[i], yerr=[ values_std[i] ])
    ax.set_xticks([0.25, 1.75])
    ax.set_xticklabels(["No Sync", "Sync"])
    ax.legend(loc="upper right", prop={"size" : 6})

# Temporary graphs for now
rocks = g.Bar(bnw, ["ops"], label="RocksDB")
rockswal = g.Bar(bw, ["ops"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["ops"], label="SLS-100Hz")
aurorawal = g.Bar(aw, ["ops"], label="SLS+WAL")
#g1 = sb.plan_graph(g.BarGraph([aurora, rocks, aurorawal, rockswal], out="fig5a.svg"))
g1 = sb.plan_graph(
        g.CustomGraph(
            [aurora, rocks, aurorawal, rockswal], 
            rocks_graph, 
            out="rocksthroughput.pgf",
            formatter = [
                format.yaxis_formatter(label="Operations per second"),
                format.set_size(3, 2),
            ]
        )
)
