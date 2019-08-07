import math
import csv
import matplotlib.pyplot as plt

linestyles = ['-','--','-.',':','.',',','o']
colors = ['b','r','g','c','m','y','k']


class Figure:

    def __init__(self, title, *argv):
        self.figure = title
        self.graphs = []
        for arg in argv:
            self.graphs.append(arg)

    def fig(self):
        c = math.sqrt(len(self.graphs))
        # Square figure
        if (c == int(c)):
            dimensions = (int(c), int(c))     
        # Horizontal
        else:
            dimensions = (1, len(self.graphs))

        f = plt.figure(self.figure, figsize=(8,8))
        plt.clf()
        index = 1
        axs = f.subplots(dimensions[0], dimensions[1], sharey=True);
        translate = dict()
        index = 0;
        for i, row in enumerate(axs):
            for t, x in enumerate(row):
                translate[index] = (i, t)
                index += 1

        for i, graph in enumerate(self.graphs):
            (x, y) = translate[i];
            for k, v in graph.ycords.items():
                axs[x, y].errorbar(graph.xcords, v,
                        yerr=graph.stddev[k], label=graph.header[(2 * k) + 1])
                index += 1
            axs[x, y].set_xlabel(graph.xlabel)
            axs[x, y].set_ylabel(graph.ylabel)
            axs[x, y].legend()

    def show(self):
        self.fig()
        plt.show()        

class LineGraph:

    def __init__(self, csv_path, xlabel, ylabel, title):
        with open(csv_path) as f:
            vals = csv.reader(f, delimiter=',')
            self.header = next(vals, None)
            num_lines = len(self.header) - 1
            if (num_lines % 2) != 0:
                print("Improper CSV formating for {}".format(csv_path))
                return;
            else:
                num_lines = int(num_lines / 2)
            
            
            self.xcords = []
            self.ycords = dict()
            self.stddev = dict()
            for x in range(0, num_lines):
                self.ycords[x] = []
                self.stddev[x] = []
            self.xlabel = xlabel
            self.ylabel = ylabel
            self.title = title
            for row in vals:
                self.xcords.append(int(row[0]))
                for line in range(0, num_lines):
                    self.ycords[line].append(int(row[(line * 2) + 1]))
                    self.stddev[line].append(int(row[((line + 1) * 2)]))

    def remove_point(self, point):
        self.xcords.pop(point)
        for k, v in self.ycords.items():
            self.ycords[k].pop(point)

        for k, v in self.stddev.items():
            self.stdev[k].pop(point)
