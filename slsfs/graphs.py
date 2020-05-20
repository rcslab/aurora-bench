from os import listdir
from os.path import isfile, join
import numpy as np
import matplotlib as mpl
import csv

mpl.use("pgf")
pgf_with_pdflatex = {
        "font.size" : 10,
        "pgf.texsystem" : "pdflatex",
        "pgf.rcfonts": False,
}

import matplotlib.pyplot as plt

plt.rcParams.update(pgf_with_pdflatex)

def clean(val):
    tmp = [x for x in val if (x.isdigit() or x == '.')]
    return (''.join(tmp))

def extract_filebench(path):
    # Extract into arrays of [ name, ops, ops/s, mb/s, ms/op ]
    operations = []
    with open(path) as file:
        started = False
        for line in file:
            if "Per-Operation" in line:
                started = True
                continue
            elif "Shutting down" in line:
                break
            elif "IO Summary" in line:
                vals = line.split(":")[2].split()
                next = []
                next.append("Summary")
                next.append(clean(vals[0]))
                next.append(clean(vals[2]))
                next.append(clean(vals[6]))
                next.append(clean(vals[7]))
                operations.append(next)
            elif started:
                vals = line.split()
                # Get rid of last elements
                vals.pop()
                vals.pop()
                vals.pop()
                for x in range(1, len(vals)):
                    vals[x] = clean(vals[x])
                operations.append(vals)
    return operations


def extract_runs(path):
    entries = listdir(path)
    data = {}
    for file in entries:
        name = file.split('.')[0]
        if ".swp" in file:
            continue
        data[name] = extract_filebench(path + "/" + file)
    return data
    
def extract_benchmarks(path):
    entries = listdir(path)
    data = {}
    for file in entries:
        data[file] = extract_runs(path + "/" + file)
    return data

def create_summary(data):
    labels = []
    values = []
    benchmarks = {}

    for i, (name, vals) in enumerate(data["sls"].items()):
        labels.append(name)
    for i, (bench, vals) in enumerate(data.items()):
        benchmarks[bench] = [] 
        for label in labels:
            val = [ x[3] for x in data[bench][label] if x[0] == "Summary" ][0]
            benchmarks[bench].append(val)

    return labels, benchmarks


def create_histogram(labels, values):
    x = np.arange(len(labels))
    width = 0.10
    fig, ax = plt.subplots()
    # print(labels)
    # print(values)
    start = x - ((len(values.keys())/2) * width);
    for k, v in values.items():
        vals = [ float(s) for s in v ]
        ax.bar(start, vals, width, label=k)
        start += width
    ax.set_ylabel("mb/s")
    ax.set_title("Throughput of Various Filebench Benchmarks")
    ax.set_xticks(x)
    ax.set_xticklabels(labels)
    ax.legend()

    fig.tight_layout()
    plt.savefig('check.svg')



data = extract_benchmarks("data")
labels, values = create_summary(data)
create_histogram(labels, values)
