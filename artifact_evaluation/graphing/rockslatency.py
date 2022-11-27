import math
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
                    median = float(tmp[2].strip().split()[2])
                    nine = float(tmp[2].strip().split()[6])
                    ninenine = float(tmp[2].strip().split()[8])

                    metrics.add_metric("avg", avg)
                    metrics.add_metric("median", median)
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

def rocks_graph(ax, data, options={}):
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
    if "log" in options and options["log"]:
        ax.set_yscale("log")
        #ax.set_ylim([1, options["ylim"]])
        ax.set_ylim(1, options["ylim"])
    if "legend" in options and options["legend"]:
        ax.legend(prop={"size" : 6})

HORIZONTAL=7.0
VERTICAL=2

# Temporary graphs for now
rocks = g.Bar(bnw, ["ops"], label="RocksDB")
rockswal = g.Bar(bw, ["ops"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["ops"], label="SLS-100Hz")
aurorawal = g.Bar(aw, ["ops"], label="SLS+WAL")
#g1 = sb.plan_graph(g.BarGraph([aurora, rocks, aurorawal, rockswal], out="fig5a.pgf"))
g1 = sb.plan_graph(
        g.CustomGraph(
            [aurora, rocks, aurorawal, rockswal], 
            rocks_graph, 
            out="throughput.pgf",
            formatter = [
                format.yaxis_formatter(label="Operations per second"),
            ],
        )
)

rocks = g.Bar(bnw, ["avg"], label="RocksDB")
rockswal = g.Bar(bw, ["avg"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["avg"], label="SLS-100Hz")
aurorawal = g.Bar(aw, ["avg"], label="SLS+WAL")
g2 = sb.plan_graph(
        g.CustomGraph(
            [aurora, rocks, aurorawal, rockswal], 
            rocks_graph, 
            out="latency-avg.pgf",
            formatter = [
                format.yaxis_formatter(label="Latency (us)"),
                format.set_size(HORIZONTAL, VERTICAL),
                format.set_title("Average"),
            ],
            options = { "log" : True, "ylim" : 5 * 10 ** 3},
        )
)


rocks = g.Bar(bnw, ["median"], label="RocksDB")
rockswal = g.Bar(bw, ["median"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["median"], label="SLS-100Hz")
aurorawal = g.Bar(aw, ["median"], label="SLS+WAL")
g3 = sb.plan_graph(
        g.CustomGraph(
            [aurora, rocks, aurorawal, rockswal], 
            rocks_graph, 
            out="latency-median.pgf",
            formatter = [
                format.set_size(HORIZONTAL, VERTICAL),
                format.set_title("Median"),
            ],
            options = { "log" : True, "legend": True, "ylim" : 5 * 10 ** 3},
        )
)


rocks = g.Bar(bnw, ["99"], label="RocksDB")
rockswal = g.Bar(bw, ["99"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["99"], label="SLS-100Hz")
aurorawal = g.Bar(aw, ["99"], label="SLS+WAL")
g4 = sb.plan_graph(
        g.CustomGraph(
            [aurora, rocks, aurorawal, rockswal], 
            rocks_graph, 
            out="latency-99.pgf",
            formatter = [
                format.set_size(HORIZONTAL, VERTICAL),
                format.set_title("99th percentile"),
            ],
            options = { "log" : True, "ylim" : 10 ** 5},
        )
)

rocks = g.Bar(bnw, ["99.9"], label="RocksDB")
rockswal = g.Bar(bw, ["99.9"], label="RocksDB+WAL")
aurora = g.Bar(anw, ["99.9"], label="SLS-100Hz")
aurorawal = g.Bar(aw, ["99.9"], label="SLS+WAL")
g5 = sb.plan_graph(
        g.CustomGraph(
            [aurora, rocks, aurorawal, rockswal], 
            rocks_graph, 
            out="latency-999.pgf",
            formatter = [
                format.set_size(HORIZONTAL, VERTICAL),
                format.set_title("99.9th percentile"),
            ],
            options = { "log" : True, "ylim" : 10 ** 5},
        )
)

sb.plan_figure(
    "rockslatency.pgf",
    [
        [ g2, g3, g4, g5]
    ],
)
