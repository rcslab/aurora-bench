import sys

prefix = sys.argv[1:-1]
suffix = sys.argv[-1]

lines = []

for each in prefix:
    filename = each+"-"+suffix
    lines += [each+"\t"+line[:-1] for line in open(filename)]

for each in lines:
    print(each)
