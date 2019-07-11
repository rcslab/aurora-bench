from bench import *

@Benchmarker
def memory(args):
    memory = args.max_mem * GB
    step = int(memory / args.num_steps)
    bits = step.bit_length();
    if step <= 2**bits:
        bits -= 1
    step = 2**bits
    params = dict()
    params["-s"] = args.run_for
    params["variable"] = "-m"
    params["-t"] = 1
    for t in range(step, memory, step):
        params["-m"] = t
        print(("=" * 10) + str(step) + ("=" * 10))
        run_benchmark("memory_bench", args, params)

@Benchmarker
def threads(args):
    step = int( args.max_threads / args.num_steps)
    params = dict()
    params["-s"] = args.run_for
    params["variable"] = "-t"
    for t in range(step, args.max_threads + 1, step):
        params["-t"] = t
        run_benchmark("thread_bench", args, params)

@Benchmarker
def memobj(args):
    step = int(args.num_obj / args.num_steps)
    params = dict()
    params["-s"] = args.run_for
    params["variable"] = "-o"
    params["-t"] = 1
    memory = args.max_mem * GB
    for t in range(step, args.num_obj + 1, step):
        params["-o"] = t
        params["-m"] = int(memory / t)
        run_benchmark("memobj_bench", args, params)

@Benchmarker
def files(args):
    step = int(args.num_files / args.num_steps)
    params = dict()
    params["-s"] = args.run_for
    params["variable"] = "-f"
    params["-t"] = 1
    for t in range(step, args.num_files + 1, step):
        params["-f"] = t
        run_benchmark("file_bench", args, params)

Benchmarker.run()
