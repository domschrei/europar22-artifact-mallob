
import sys

filename = sys.argv[1]
width_seconds = float(sys.argv[2])

window = []
sumofweightedtimes = 0
sumofweightedutils = 0
sumofweights = 0

lasttime = 0
lastutil = 0

for line in open(filename, 'r').readlines():
    
    words = line.rstrip().split(" ")
    newtime = float(words[0])
    newutil = float(words[1])

    time = (lasttime+newtime)/2
    util = lastutil
    weight = newtime - lasttime
    
    i = 0
    while i < len(window):
        (oldtime, oldutil, oldweight) = window[i]
        if time-oldtime <= width_seconds:
            break
        sumofweightedtimes -= oldweight*oldtime
        sumofweightedutils -= oldweight*oldutil
        sumofweights -= oldweight
        i += 1
    
    #print(time, util, weight)
    window = window[i:] + [(time,util,weight)]
    sumofweights += weight
    sumofweightedtimes += weight*time
    sumofweightedutils += weight*util

    if sumofweights > 0:
        avgtime = sumofweightedtimes / sumofweights
        avgutil = sumofweightedutils / sumofweights
        print(avgtime, avgutil)
    
    lasttime = newtime
    lastutil = newutil

