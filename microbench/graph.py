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
        for graph in self.graphs:
            plt.subplot(*dimensions, index)
            print(graph.stddev)
            plt.errorbar(graph.xcords, graph.ycords,
                    yerr=graph.stddev)
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
            self.xcords = []
            self.ycords = []
            self.stddev = []
            self.xlabel = xlabel
            self.ylabel = ylabel
            self.title = title
            for row in vals:
                if len(row) != 3:
                    continue
                self.xcords.append(row[0])
                self.ycords.append(row[1])
                self.stddev.append(row[2])

            # Remove Titles
            self.remove_point(0)
            # Make ints
            self.xcords = list(map(int, self.xcords))
            self.ycords = list(map(int, self.ycords))
            self.stddev = list(map(int, self.stddev))

    def remove_point(self, point):
        self.xcords.pop(point)
        self.ycords.pop(point)
        self.stddev.pop(point)
