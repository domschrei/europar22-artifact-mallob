
# (prio, demand, marked_volume)
jobs = [
    [1,200,-1], [100,2,-1], [200,1,-1],
]
V = 202

def p(j):
    return j[0]
def d(j):
    return j[1]

n = len(jobs)
P = sum([p(j) for j in jobs])

def fs(j):
    if j[2]>0:
        return "-"
    return V * p(j) / P

def vol(j):
    if j[2]<0:
        return "-"
    return j[2]

def commit_small(j):
    
    global P,V
    V -= 1
    P -= p(j)
    j[2] = 1

def commit_big(j):
    global P,V
    V -= d(j)
    P -= p(j)
    j[2] = d(j)

def uncommit(j):
    global P,V
    V += j[2]
    P += p(j)
    j[2] = -1

def is_committed(j):
    return j[2] > 0

A = sorted(jobs, key=lambda j: p(j))
B = sorted(jobs, key=lambda j: p(j)/d(j))

def print_step():
    print("fs =", [fs(j) for j in jobs], " vs =", [vol(j) for j in jobs], " V =", str(V), " P =", str(P))

print(A)
print(B)
print_step()

idx = -1
for j in A:
    if fs(j) < 1:
        print("commit A", str(j))
        commit_small(j)
        print_step()
        idx += 1
        continue
    break

idxb = len(B)
for j in reversed(B):
    #V += d(j)
    #P += p(j)
    was_committed = False
    if is_committed(j):
        was_committed = True
        uncommit(j)
    if not is_committed(j) and fs(j) > d(j):
        print("commit B", str(j))
        commit_big(j)
        print_step()
        idxb -= 1
        continue
    if was_committed:
        commit_small(j)
    break

for i in reversed(range(0, idx+1)):
    j = A[i]
    uncommit(j)
    print(str(j), ": fair share would be", str(fs(j)))
    if fs(j) >= 1:
        print("uncommit", str(j))
        continue
    commit_small(j)
    break

print_step()

for i in range(idxb, len(B)):
    j = B[i]
    uncommit(j)
    print(str(j), ": fair share would be", str(fs(j)))
    commit_big(j)

