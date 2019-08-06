import errno
import subprocess
import sys
import os
import configargparse
import shutil
import re
import numpy
import time

from graph import *

KB = 1024
MB = 1024 * KB
GB = 1024 * MB
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
    def wrap(file, args, params):
        for x in range(1, args.repeat + 1):
            print("Benchmark {} running {} out of {}".format(file, x,  \
                args.repeat))
            func(file, args, params)
            save_data(file.split("_")[0], 
                    str(params[params["variable"]]) + "-" + str(x))

    return wrap

@repeater
def run_benchmark(file, args, params):
    name = file.split("_")[0]
    p = []
    for flag, value in params.items():
        if (flag == "variable"):
            continue
        p.append(str(flag))
        p.append(str(value))
    subprocess.run(["./run.sh", file, args.sls_dir,
            args.mount_dir, args.freq] + p)

def aggregate():

    def parse_trace(path, name):
        values = dict()
        with open(path, 'r') as f:
            for line in f:
                line = line.strip()
                if (line == ""):
                    continue
                if (line == "Counts"):
                    break 
                columns = re.split(r'\s{2,}', line);
                if len(columns) == 2:
                    values[columns[0]] = int(columns[1].strip())

        if(len(values) > 0):
            title = int(name.split(".")[0].split("-")[0])

            return (title, values["sls_stop_proc"],
                        values["SIGSTOP to SIGCONT"])
        else:
            time.sleep(1)
            print("RETRYING " + path)

            return parse_trace(path, name)

            
    def tablify(path, name):
        values = dict()
        for trace in os.listdir(path):
            new_path = path + "/" + trace
            header, stop, cont = parse_trace(new_path, trace)
            if header in values:
                values[header]["s"].append(stop)
                values[header]["c"].append(cont)
            else:
                values[header] = dict()
                values[header]["s"] = [stop]
                values[header]["c"] = [cont]

        return sorted(values.items(), key = lambda x : x[0])
    
    for dir in os.listdir("data"):
        path = "data/" + dir
        values = tablify(path, dir)
        with open("data/" + dir + ".csv", "a+") as f:
            f.write(dir + \
                ", stop(ns), stop-stddev(ns), cont(ns), cont-stddev(ns)\n")
            for h, v in values:
                f.write("{},{},{},{},{}\n".format(h, int(numpy.mean(v["s"])), 
                    int(numpy.std(v["s"])), int(numpy.mean(v["c"])), 
                    int(numpy.std(v["c"]))))

class Benchmarker:
    bm = []

    @staticmethod
    def run():
        print("\n")
        print("Running the following benchmarks:")
        for x in Benchmarker.bm:
            print(x.__name__)
        print("\n")
        args = Benchmarker.get_parser().parse_args()
        print(args)
        print("\n")
        Benchmarker.run_with_args(args)

    @staticmethod
    def show():
        graphs = []
        for dir in os.listdir("./data"):
            if os.path.isdir("./data/" + dir):
                continue
            (name, ext) = dir.split(".")
            if ext == "csv":
                graphs.append(LineGraph("./data/" + dir, name.capitalize(), 
                    "us", name.capitalize()))

        fig = Figure("Microbenchmarks", *graphs)
        fig.show()

    @staticmethod
    def run_with_args(args):
        for f in Benchmarker.bm:
            f(args)
        time.sleep(5)
        aggregate()

    def __init__(self, func):
        self.func = func
        Benchmarker.bm.append(func)
    
    def __call__(self, *args, **kwards):
        return self.func(*args, **kwargs)

    @staticmethod
    def get_parser():

        parser = configargparse.ArgumentParser(
                    default_config_files=["./bench.conf"],
                    description="SLS Micro benchmark")
        parser.add("-c", "--config", 
                is_config_file=True, 
                help= "Location of SLS directory (must be build)", 
                metavar='path')

        parser.add("--sls-dir", required=True, help= \
                "Location of SLS directory (must be build)", metavar='path')
        parser.add("--mount-dir", required=True, help= \
                "Directory for SLS file", metavar='path')
        parser.add("--freq", help= \
                "Frequency of checkpointing", metavar='milliseconds')
        parser.add("--max-mem", type=int, default=DEFAULT_MAXMEM, help= \
                "Maximum memory for benchmark", metavar='Gb')
        parser.add("--num-obj", type=int, default=1, help= \
                "Max number of memory objects. Object size = max-mem / num-obj", 
                metavar='')
        parser.add("--num-files", type=int, default=1, help= \
                "Number of files for the file micro benchmark", metavar='')
        parser.add("--max-threads", type=int, default=24, help= \
                "Maximum threads that will be spawned for benchmark", metavar='')
        parser.add("--run-for", type=int, default=10, help= \
                "Run each benchmark for this long", metavar='seconds')
        parser.add("--num-steps", type=int, default=1, help= \
                "How many step to get from min to max", metavar='')
        parser.add("--repeat", type=int, default=1, help= \
                "Repeat each benchmark this many times", metavar='')
        return parser

