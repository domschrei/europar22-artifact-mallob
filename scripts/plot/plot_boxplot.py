#!/usr/bin/env python3
 
import math
import sys
import re

files = []
logscale = False
outfile = None
xlabel = None
ylabel = None
for arg in sys.argv[1:]:
    if arg.startswith("-o="):
        outfile = arg[3:]
    elif arg.startswith("-labels="):
        labels = arg[len("-labels="):].split(",")
    elif arg.startswith("-xlabel="):
        xlabel = arg[8:]
    elif arg.startswith("-ylabel="):
        ylabel = arg[8:]
    elif arg.startswith("-log"):
        logscale = True
    else:
        files += [arg]

import matplotlib
if outfile:
    matplotlib.use('pdf')
matplotlib.rcParams['hatch.linewidth'] = 0.5  # previous pdf hatch linewidth
import matplotlib.pyplot as plt
from matplotlib import rc
rc('font', family='serif')
#rc('font', serif=['Times'])
rc('text', usetex=True)

data = []
for f in files:
    filedata = []
    for l in open(f, 'r').readlines():
        l = l.rstrip()
        filedata += [float(l)]
    data += [filedata]

plt.figure(figsize=(4,3))
plt.boxplot(data, labels=labels)
if xlabel:
    plt.xlabel(xlabel)
if ylabel:
    plt.ylabel(ylabel)
if logscale:
    plt.yscale("log")

plt.tight_layout()
if outfile:
    plt.savefig(outfile, dpi=300)
else:
    plt.show() 
