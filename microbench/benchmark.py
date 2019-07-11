import errno
import subprocess
import sys
import os
import argparse
import shutil
import re
import numpy

DEFAULT_MAXMEM = 2 * (1024*1024*1024)
MIN_MEM = 1024
MIN_THREADS = 1

def save_data(dir, filename):
    path = "data/" + dir
    try:
        os.makedirs(path)
    except OSError as exc:
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else:
            raise
    os.rename("./trace.log", path + "/" + str(filename) + ".trace")

def repeater(func):
    def wrap(file, args, params, naming):
        for x in range(1, args.repeat + 1):
            print("Benchmark {} running {} out of {}".format(file, x,  \
                args.repeat))
            func(file, args, params, naming)
            save_data(file.split("_")[0], str(params[naming]) + "-" + str(x))

    return wrap

@repeater
def run_benchmark(file, args, params, naming):
    name = file.split("_")[0]
    p = []
    for flag, value in params.items():
        p.append(str(flag))
        p.append(str(value))

    subprocess.run(["./run.sh", file, args.sls_dir, \
            args.mount_dir, args.freq] + p)

def aggregate():

    def parse_trace(path, name):
        values = dict()
        with open(path, 'r') as f:
            for line in f:
                line = line.strip();
                if (line == ""):
                    continue
                columns = re.split(r'\s{2,}', line);
                if len(columns) == 2:
                    values[columns[0]] = int(columns[1].strip())
        time = values["sls_stop_proc"] + values["SIGSTOP to SIGCONT"]
        title = int(name.split(".")[0].split("-")[0])
        return (title, time)
            
    def tablify(path, name):
        values = dict()
        for trace in os.listdir(path):
            new_path = path + "/" + trace
            header, val = parse_trace(new_path, trace)
            if header in values:
                values[header].append(val)
            else:
                values[header] = [val]
        return sorted(values.items(), key = lambda x : x[0])
    
    for dir in os.listdir("data"):
        path = "data/" + dir
        values = tablify(path, dir)
        print("X, Y, dev")
        for h, v in values:
            print(h, numpy.mean(v), numpy.std(v))

def threads(arg):
    step = int((args.max_threads - MIN_THREADS) / args.num_steps)
    params = dict()
    params["-s"] = args.run_for
    for t in range(MIN_THREADS, args.max_threads + 1, step):
        params["-t"] = t
        run_benchmark("thread_bench", args, params, naming="-t");


parser = argparse.ArgumentParser(description="SLS Micro benchmark")
parser.add_argument("--sls-dir", required=True, help= \
        "Location of SLS directory (must be build)")
parser.add_argument("--freq", required=True, help= \
        "Frequency of checkpointing")
parser.add_argument("--mount-dir", required=True, help= \
        "Directory for SLS file")
parser.add_argument("--max-mem", type=int, default=DEFAULT_MAXMEM, help= \
        "Maximum memory for benchmark")
parser.add_argument("--max-threads", type=int, default=24, help= \
        "Maximum threads that will be spawned for benchmark")
parser.add_argument("--run-for", type=int, default=10, help= \
        "Run each benchmark for this long")
parser.add_argument("--num-steps", type=int, default=1, help= \
        "How many step to get from min to max")
parser.add_argument("--repeat", type=int, default=1, help= \
        "Repeat each benchmark this many times")

args = parser.parse_args()

threads(args)
aggregate()
