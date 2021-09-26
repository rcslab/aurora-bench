#!/usr/bin/env python3

from sys import argv
import csv

def extract_percentiles(filepath):
    with open(filepath, newline='') as csvfile:
        table_reader = csv.reader(csvfile, delimiter='\t')
        for i in range(0, 5):
            next(table_reader)

        inctbl = dict()
        atomtbl = dict()
        journaltbl = dict()
        for row in table_reader:
            size = row[0].strip().rstrip()

            incremental = row[2]
            print("INCREMENTAL")
            print(incremental)
            if size in inctbl:
                inctbl[size].append(int(incremental.strip("us")))
            else:
                inctbl[size] = [int(incremental.strip("us"))]

            atomic = row[4]
            print("ATOMIC")
            print(atomic)
            if size in atomtbl:
                atomtbl[size].append(int(atomic.strip("us")))
            else:
                atomtbl[size] = [int(atomic.strip("us"))]

            journal = row[5]
            print("JOURNAL")
            print(journal)
            if size in journaltbl:
                journaltbl[size].append(int(journal.strip("us")))
            else:
                journaltbl[size] = [int(journal.strip("us"))]


        print("SIZE\tINCREMENTAL\tATOMIC\tJOURNAL")
        for key in inctbl.keys():
            avginc = sum(inctbl[key])/len(inctbl[key])
            avgatom = sum(atomtbl[key])/len(atomtbl[key])
            avgjournal = sum(journaltbl[key])/len(journaltbl[key])
            print("{}\t{}\t\t{}\t{}".format(key, avginc, avgatom, avgjournal))


if __name__ == "__main__":
    extract_percentiles(argv[1])
