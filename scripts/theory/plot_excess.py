
demands =    [2, 10, 5s, 2]
priorities = [1, 2, 3, 10]

# alpha0 = 0.8, m=7
# v1 = 0.8 => 1
# v2 = 1.6
# v3 = 2.4
# v4 = 8 => 2

#m = 10

def excess(alpha):
    sum = 0
    for j in range(len(demands)):
        sum += max(1, min(demands[j], alpha*priorities[j]))
    return 7 - sum

f = open("data/excess", 'w')
alpha = 0.01
while alpha < 100:
    f.write(str(alpha) + " " + str(excess(alpha)) + "\n")
    alpha += 0.01
f.close()

lpivots = []
upivots = []
for j in range(len(demands)):
    lower = 1/priorities[j]
    upper = demands[j]/priorities[j]
    lpivots += [lower]
    upivots += [upper]
lpivots.sort()
upivots.sort()

f = open("data/excess_pivots_lower", "w")
for p in lpivots:
    f.write(str(p) + " " + str(excess(p)) + "\n")
f = open("data/excess_pivots_upper", "w")
for p in upivots:
    f.write(str(p) + " " + str(excess(p)) + "\n")
