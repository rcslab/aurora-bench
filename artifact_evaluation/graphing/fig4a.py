import progbg as sb
import progbg.graphing as g
import progbg.formatters as f
import os
import re

ROOT_DIR=os.environ["OUT"]
MODE=os.environ["MODE"]
HOSTS=os.environ["EXTERNAL_HOSTS"].split()

if MODE == "VM":
    fs = ["100", "200", "300", "400", "500", "600", "700", "800", "900", "1000"]
else:
    fs = ["10", "20", "30", "40", "50", "60", "70", "80", "90", "100"]

def get_num(val):
    try:
        return float(val)
    except:
        for i, x in enumerate(val):
            if x.isnumeric() or x == ".":
                continue
            break

        return float(val[:i])

def parse_redis(metrics, path):
    pattern = re.compile("Throughput")
    result = None
    throughputs = []
    with open(path) as f:
        for line in f:
            line = str(line.encode('UTF-8'))
            if "Throughput" in line:
                t = get_num(line.split()[-1])
                if t == 0:
                    break
                throughputs.append(t)
            if "Connection refused" in line:
                print("Connection refused error!")
                break
        if len(throughputs) != len(HOSTS):
            print("[Error] {} did not execute or pre-emptively shut down, please re-run fig4a.sh".format(path))
            os.unlink(path)
        else:
            metrics.add_metric("throughput", sum(throughputs))

base_path = os.path.join(ROOT_DIR, "redis")
const_base = os.path.join(base_path, "base")
base = sb.plan_parse(const_base, const_base, parse_redis)

execs = []
for x in fs:
    freq_path = os.path.join(base_path, x)
    execs.append(sb.plan_parse(freq_path, freq_path, parse_redis))


x=[ int(x) for x in fs ]
l1 = g.Line(execs, "throughput", x=x, label="With Aurora")
l2 = g.ConstLine(base, "Base", "throughput")
fig4a = sb.plan_graph(g.LineGraph([l1, l2], std=True,
    out="fig4a.svg",
    formatters=[ 
        f.set_size(10, 5),
        f.set_yrange(0, None),
        f.yaxis_formatter(label="Operations per second"),
        f.xaxis_formatter("Checkpoint Period"),
        f.set_title("Redis with Aurora"),
    ]
))
