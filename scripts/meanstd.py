import sys
import numpy as np

data = [float(line) for line in sys.stdin]
print(np.mean(data), np.std(data))
