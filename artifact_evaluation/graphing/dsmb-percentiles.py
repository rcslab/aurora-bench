#!/usr/bin/env python3

import numpy as np
from sys import argv
import csv

def extract_percentiles(filepath):
    with open(filepath, newline='') as csvfile:
        percent_reader = csv.reader(csvfile, delimiter=' ')
        latencies = [int(row[1]) for row in percent_reader]
        nplat = np.array( [ [float(lat)] for lat in latencies ])


    #print(sorted(latencies))
    for percentile in [50, 90, 95, 97, 98, 99, 99.9]:
        print("{}th percentile: {}".format(percentile, np.percentile(nplat, percentile)))


if __name__ == "__main__":
    extract_percentiles(argv[1])
