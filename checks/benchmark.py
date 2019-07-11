import subprocess
import sys
import os


def run_benchmark(file):
    name = file.split("_")[0]
    print("\n")
    print("Benchmark " + file + " started")
    print("\n")
    print("Test output")
    print("===========")
    print("\n")
    subprocess.run(["./run.sh", file] + sys.argv[1:])
    print("\n")
    print("===========")
    print("\n")
    print("Benchmark " + file + " complete")
    print("\n")

for f in os.listdir("./"):
    splits = f.split("_")
    if (len(splits) > 1 and splits[1] == "bench"):
        run_benchmark(f)
