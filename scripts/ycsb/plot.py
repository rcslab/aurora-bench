import numpy as np
import matplotlib.pyplot as plt
import sys

def load_data():
    mean = [[each[0] for each in data] for data in raw]
    std = [[each[1] for each in data] for data in raw]
    return mean, std

def barplot(files, keys):
    data = [{line.split()[0]:[float(i) for i in line.split()[1:]] 
        for line in open(f) if line.split()[0] in keys} for f in files]
    for each in data:
        print(each)

    fig, ax = plt.subplots()
    width = 1 / (len(files) + 1)
    idx = np.arange(len(keys))

    baseline = np.array([1/data[0][key][0] for key in keys])

    for i in range(len(files)):
        mean = np.array([data[i][key][0] for key in keys]) * baseline
        std = np.array([data[i][key][1] for key in keys]) * baseline
        print(mean)
        print(std)
        ax.bar(idx+i*width, mean, width, yerr=std, label=files[i][:files[i].find('.')]) 

    ax.set_xlabel("Requests")
    ax.set_xticks(idx+width/2)
    ax.set_xticklabels(keys)
    ax.legend()

    #plt.show()
    plt.savefig("plot.svg", dpi=100000)


#keys = ["heavy", "latest", "mostread", "onlyread", "rmw", "short"]
keys = ["heavy", "short"]
barplot(sys.argv[1:], keys)
