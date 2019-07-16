import sys

prefix = sys.argv[1:-1]
exptype = sys.argv[-1]

lines = []

for each in prefix:
    filename = exptype+'-'+each+".sum"
    lines += [each+"\t"+line[:-1] for line in open(filename)]

for each in lines:
    print(each)
