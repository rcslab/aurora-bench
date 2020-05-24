import csv

conf_name = "redis.conf"
csv_name = "redis.conf.csv"

def tuple_generate(conf_file):
    lines = conf_file.readlines()
    for line in lines:
        if not line.strip().startswith("#"):
            yield line.strip().split()

with open(csv_name, 'w') as csv_file:
    csv_writer = csv.writer(csv_file, delimiter=' ')
    with open(conf_name) as conf_file:
        for tup in tuple_generate(conf_file):
            if tup:
                csv_writer.writerow(tup)
