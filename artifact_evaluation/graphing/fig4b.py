import progbg as sb
import progbg.graphing as g
import progbg.formatters as f
import os

ROOT_DIR=os.environ["OUT"]

def get_num(val):
    try:
        return float(val)
    except:
        for i, x in enumerate(val):
            if x.isnumeric() or x == ".":
                continue
            break

        return float(val[:i])


def parse_memcached(metrics, path):
    result = None
    with open(path) as f:
        for line in f:
            line = str(line.encode('UTF-8'))
            if "Total QPS" in line:
                result = line
                break
        if result is None:
            print("[Error] {} did not execute or pre-emptively shut down, please re-run fig4b.sh".format(path))
            os.unlink(path)
            exit(0)
        else:
            t = result.split()
            metrics.add_metric("throughput", get_num(t[3]))


fs = ["10", "20", "30", "40", "50", "60", "70", "80", "90", "100"]
base_path = os.path.join(ROOT_DIR, "memcached")
execs = []
for x in fs:
    freq_path = os.path.join(base_path, x)
    execs.append(sb.plan_parse(freq_path, freq_path, parse_memcached))

const_base = os.path.join(base_path, "base")
base = sb.plan_parse(const_base, const_base, parse_memcached)

x=[x for x in range(10, 110, 10)]
l1 = g.Line(execs, "throughput", x=x)
l2 = g.ConstLine(base, "Base", "throughput")
fig4b = sb.plan_graph(
            g.LineGraph([l1, l2], std=True,
                out="fig4b.svg",
                formatters=[ 
                    f.set_size(10, 5),
                    f.set_yrange(0, 300000)
                ]
            )
)


