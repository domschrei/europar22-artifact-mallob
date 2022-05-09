
import math
import random

for m in range(10000, 1000001, 10000):

    initial_k = int(m/2)

    all_ranks = [x for x in range(m)]
    destination_ranks = set(random.sample(all_ranks, initial_k))
    random.shuffle(all_ranks)

    current_ranks = [] #random.sample(all_ranks, initial_k)
    for rank in all_ranks:
        if rank not in destination_ranks:
            current_ranks += [rank]
        if len(current_ranks) == initial_k:
            break

    iteration = 0
    k = initial_k
    desired_k = math.sqrt(m) #math.log2(m)**2

    while True:
        if k <= desired_k:
            break

        new_current_ranks = []
        
        # For each request
        for j in range(k):
            
            rank = current_ranks[j]

            # Found its destination?
            if rank in destination_ranks:
                # Eliminate this request and destination
                destination_ranks.remove(rank)
                continue

            # Did not find its destination: draw new rank, keep request
            while rank == current_ranks[j]:
                rank = random.randint(0, m-1)
            new_current_ranks += [rank]
        
        current_ranks = new_current_ranks
        k = len(current_ranks)
        #print("Iteration", iteration, ":", k, "remaining")
        iteration += 1
    
    print(m,iteration)
