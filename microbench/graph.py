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

        plt.figure(self.figure, figsize=(8,8))
        plt.clf()
        index = 1
        f, axs = plt.subplots(dimensions[0], dimensions[1], sharey=True);
        translate = dict()
        index = 0;
        for row in axs:
            for x in row:
                translate[index] = x
                index += 1

        for i, graph in enumerate(self.graphs):
            for k, v in graph.ycords.items():
                translate[i].errorbar(graph.xcords, v,
                        yerr=graph.stddev[k])
            plt.xlabel(graph.xlabel)
            plt.ylabel(graph.ylabel)
            index += 1

    def show(self):
        self.fig()
        plt.show()        

class LineGraph:

    def __init__(self, csv_path, xlabel, ylabel, title):
        with open(csv_path) as f:
            vals = csv.reader(f, delimiter=',')
            header = next(vals, None)
            num_lines = len(header) - 1
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
