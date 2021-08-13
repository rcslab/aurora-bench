import progbg as sb
import progbg.graphing as g
import progbg.formatters as f
import os
import re

ROOT_DIR=os.environ["OUT"]

fs = ["aurora", "ffs", "zfs-off", "zfs-on"]
directories = ["macro", "micro"]

executions = {}

OP = 3
OPS = 5
MBS = 9

def get_num(val):
    try:
        return float(val)
    except:
        for i, x in enumerate(val):
            if x.isnumeric() or x == ".":
                continue
            break

        return float(val[:i])

def parse(metrics, path):
    pattern = re.compile("^.*IO Summary: .*$")
    result = None
    with open(path) as f:
        for line in f:
            result = re.match(pattern, line)
            if result:
                break
    if result is None:
        print("[Error] {} did not execute or pre-emptively shut down, please re-run fig3.sh".format(path))
        print(open(path).read())
        os.unlink(path)
        exit(0)
    else:
        t = result.group(0).split()
        metrics.add_metric("operations", get_num(t[OP]))
        metrics.add_metric("operations_ps", get_num(t[OPS]))
        metrics.add_metric("mib_ps", get_num(t[MBS]))
    return

for filesystem in fs:
    path = os.path.join(ROOT_DIR, "filesystem", filesystem)
    executions[filesystem] = {}
    for workload in directories:
        workload = os.path.join(path, workload)
        for dir in os.listdir(workload):
            full = os.path.join(workload, dir)
            name = "{}-{}".format(filesystem, dir)
            executions[filesystem][dir] = sb.plan_parse(name, full, parse)

def change_axis_label(labels):
    def tmp(fig, axes):
        axes.set_xticklabels(labels)

    return tmp

# Figure 3a
zfson = executions["zfs-on"]["randomw-4t-64k.f"]
zfsoff = executions["zfs-off"]["randomw-4t-64k.f"]
ffs = executions["ffs"]["randomw-4t-64k.f"]
aurora = executions["aurora"]["randomw-4t-64k.f"]
b1 = g.BarGroup([zfsoff, zfson, ffs, aurora], "mib_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])

zfson = executions["zfs-on"]["seqwrite-4t-64k.f"]
zfsoff = executions["zfs-off"]["seqwrite-4t-64k.f"]
ffs = executions["ffs"]["seqwrite-4t-64k.f"]
aurora = executions["aurora"]["seqwrite-4t-64k.f"]

b2 = g.BarGroup([zfsoff, zfson, ffs, aurora], "mib_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])
fig3a = sb.plan_graph(
            g.BarGraph([b1, b2], out="fig3a.svg", 
                formatters=[
                    f.xaxis_formatter("MiB/s"),
                    change_axis_label(["Random", "Sequential"]),
                ]
            )
        )

# Figure 3b
zfson = executions["zfs-on"]["randomw-4t-4k.f"]
zfsoff = executions["zfs-off"]["randomw-4t-4k.f"]
ffs = executions["ffs"]["randomw-4t-4k.f"]
aurora = executions["aurora"]["randomw-4t-4k.f"]
b1 = g.BarGroup([zfsoff, zfson, ffs, aurora], "mib_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])

zfson = executions["zfs-on"]["seqwrite-4t-4k.f"]
zfsoff = executions["zfs-off"]["seqwrite-4t-4k.f"]
ffs = executions["ffs"]["seqwrite-4t-4k.f"]
aurora = executions["aurora"]["seqwrite-4t-4k.f"]

b2 = g.BarGroup([zfsoff, zfson, ffs, aurora], "mib_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])
fig3b = sb.plan_graph(
            g.BarGraph([b1, b2], out="fig3b.svg", 
                formatters=[
                    f.xaxis_formatter("MiB/s"),
                    change_axis_label(["Random", "Sequential"]),
                ]
            )
        )


# Figure 3c
zfson = executions["zfs-on"]["createfiles-16t-64k.f"]
zfsoff = executions["zfs-off"]["createfiles-16t-64k.f"]
ffs = executions["ffs"]["createfiles-16t-64k.f"]
aurora = executions["aurora"]["createfiles-16t-64k.f"]
b1 = g.BarGroup([zfsoff, zfson, ffs, aurora], "operations_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])

zfson = executions["zfs-on"]["writedsync-4t-4k.f"]
zfsoff = executions["zfs-off"]["writedsync-4t-4k.f"]
ffs = executions["ffs"]["writedsync-4t-4k.f"]
aurora = executions["aurora"]["writedsync-4t-4k.f"]
b2 = g.BarGroup([zfsoff, zfson, ffs, aurora], "operations_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])

zfson = executions["zfs-on"]["writedsync-4t-64k.f"]
zfsoff = executions["zfs-off"]["writedsync-4t-64k.f"]
ffs = executions["ffs"]["writedsync-4t-64k.f"]
aurora = executions["aurora"]["writedsync-4t-64k.f"]
b3 = g.BarGroup([zfsoff, zfson, ffs, aurora], "operations_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])


fig3c = sb.plan_graph(
            g.BarGraph([b1, b2, b3], out="fig3c.svg", 
                formatters=[
                    f.xaxis_formatter("Operations per second"),
                    change_axis_label(["createfiles", "sync 4KiB", "sync 64KiB"]),
                ]
            )
        )


# Figure 3d
zfson = executions["zfs-on"]["fileserver.f"]
zfsoff = executions["zfs-off"]["fileserver.f"]
ffs = executions["ffs"]["fileserver.f"]
aurora = executions["aurora"]["fileserver.f"]
b1 = g.BarGroup([zfsoff, zfson, ffs, aurora], "operations_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])

zfson = executions["zfs-on"]["varmail.f"]
zfsoff = executions["zfs-off"]["varmail.f"]
ffs = executions["ffs"]["varmail.f"]
aurora = executions["aurora"]["varmail.f"]
b2 = g.BarGroup([zfsoff, zfson, ffs, aurora], "operations_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])

zfson = executions["zfs-on"]["webserver.f"]
zfsoff = executions["zfs-off"]["webserver.f"]
ffs = executions["ffs"]["webserver.f"]
aurora = executions["aurora"]["webserver.f"]
b3 = g.BarGroup([zfsoff, zfson, ffs, aurora], "operations_ps", ["ZFS", "ZFS+CSUM", "FFS", "SLS-100"])


fig3d = sb.plan_graph(
            g.BarGraph([b1, b2, b3], out="fig3d.svg", 
                formatters=[
                    f.xaxis_formatter("Operations per second"),
                    change_axis_label(["fileserver", "varmail", "webserver"]),
                ]
            )
        )



