import matplotlib.pyplot as plt

def get_num(filename, eid):
    lines = [float(line.split()[1]) for line in open(filename)]
    return lines[eid]

def plot_exp(eid):

    plt.hlines(get_num("redis-mem.sum", eid), xmin=0, xmax=1000)

    x = [10, 20, 50, 100, 200, 400, 600, 800, 1000]
    y = []

    for each in x:
        y.append(get_num("redis-sls-%d.sum" % (each), eid))

    print(y)
    plt.plot(x, y)
    plt.savefig("exp-%d.png" % (eid), format="png")

for i in range(18):
    plot_exp(i)


plt.show()
