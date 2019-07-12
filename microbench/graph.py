import math
import csv
import matplotlib.pyplot as plt

linestyles = ['-','--','-.',':','.',',','o']
colors = ['b','r','g','c','m','y','k']


class Figure:

    FigureCounter = 0

    def __init__(self, title, *argv):
        Figure.FigureCounter += 1
        self.figure = Figure.FigureCounter
        self.graphs = []
        for arg in argv:
            self.graphs.append(arg)

    def get_figure(self):
        c = math.sqrt(len(self.graphs))
        # Square figure
        if (c == int(c)):
            dimensions = (int(c), int(c))     
        # Horizontal
        else:
            dimensions = (1, len(self.graphs))

        fig = plt.figure(self.figure)
        plt.clf()
        index = 1
        for graph in self.graphs:
            ax = fig.add_subplot(dimensions[0], dimensions[1], index)
            ax.errorbar(graphs.xcords, self.ycords, yerr=graphs.stddev,
                    title=graph.title,
                    xlabel=graph.xlabel,
                    ylabel=graph.ylabel)
            index += 1

        return fig

    def show(self):
        fig = self.get_figure()
        fig.show()        

class LineGraph:

    def __init__(self, csv_path, xlabel, ylabel, title):
        vals = csv.reader(csv_path, delimiter=',')
        self.xcords = []
        self.ycords = []
        self.stddev = []
        self.xlabel = xlabel
        self.ylabel = ylabel
        self.title = title
        for row in vals:
            if len(row) != 3:
                continue
            print(row)
            self.xcords.append(row[0])
            self.ycords.append(row[1])
            self.stddev.append(row[2])

    def remove_point(self, point):
        self.xcords.pop(point)
        self.ycords.pop(point)
        self.stddev.pop(point)
