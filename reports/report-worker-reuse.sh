#!/bin/bash

set -e

if [ ! -d "$1" ]; then
    echo "First argument is not a valid directory."
    exit 1
fi

cdf_eval_points="0 1 4 9 24"

# Output header line
echo -ne "Approach CCR_med CCR_max CCR_tot CS_med CS_mean num_processed RT_mean "
# Ourput CDF description at different points
for i in $cdf_eval_points; do echo -ne "Pr[WC<=$(($i+1))] "; done
# Line break
echo ""

# Traverse all provided directories
for d in $@ ; do

    # Extract program options from logs of rank zero
    options=$(cd "$d" && cat 0/log.0|head -10|grep "Program options")
    # Extract number of clients from the program options
    numclients=$(echo $options|grep -oE " -c=[0-9]+ "|grep -oE "[0-9]+")
    # Find out which is the highest process rank
    lastclient=$(cd "$d" && echo */|tr ' ' '\n'|grep -E '^[0-9]+/$'|sort -g|tail -1|sed 's,/,,g')
    # Calculate the rank of the first client 
    firstclient=$(($lastclient - $numclients + 1))
    # Extract "dc" option
    dc=$(echo $options|grep -oE " -dc=[0-9]+ "|grep -oE "[0-9]+")
    # Extract "rs" option
    rs=$(echo $options|grep -oE " -rs=[0-9]+ "|grep -oE "[0-9]+")
    # Infer label of this run
    if [ "$rs" == 0 ] && [ "$dc" == 0 ]; then
        label="None"
    elif [ "$rs" == 0 ]; then
        label="Basic"
    else
        label="Ours"
    fi
        
    # Extract worker events from logs (this may take a minute)
    cat $d/*/log.*|grep -E ":0 : update v=|LOAD 1" > _worker_events
    
    # Calculate max. assigned volume per job
    cat _worker_events|grep ":0 : update v="|sed 's/v=\|#\|:0//g'|awk '{\
     job=$3; vol=$6; \
     maxvol[job] = maxvol[job]>vol?maxvol[job]:vol\
    } END {\
     for (job in maxvol) {\
      print("V", job, maxvol[job])\
     }\
    }' > _max_volume_per_job
    
    # Calculate number of distinct workers created for each job
    cat _worker_events|grep "LOAD 1"|sed 's/[()+#-]//g'|sed 's/:/ /g'|awk '{\
     rank=$2; job=$5; idx=$6;\
     ccs[job][idx][rank]=1;\
    } END {\
     for (job in ccs) {\
      numpes = 0;\
      for (idx in ccs[job]) {\
       for (rank in ccs[job][idx]) {\
        numpes += 1;\
       }\
      }\
      print("C", job, numpes)\
     }\
    }' > _num_distinct_workers_per_job
    
    # Merge both to compute CCR for each job
    cat _max_volume_per_job _num_distinct_workers_per_job|awk '\
    /V/ {maxvol[$2]=$3; totalvol+=$3} \
    /C/ {numdw[$2]=$3; totaldw+=$3} \
    END {\
     for (job in maxvol) {\
      if (maxvol[job] > 0 && numdw[job] > 0) {\
       print(numdw[job]/maxvol[job], job)\
      }\
     }\
     print(totaldw/totalvol, -1)\
    }' | sort -g > _ccr_per_job
    
    # Calculate statistic measures over the CCR per job and in total
    maxccr=$(cat _ccr_per_job|tail -1|awk '{print $1}')
    medianccr=$(sed $(( ($(cat _ccr_per_job|wc -l)-1) / 2 ))'q;d' _ccr_per_job|awk '{print $1}')
    totalccr=$(cat _ccr_per_job|awk '$2 == -1 {print $1}')
    
    #echo "  CCR: Max=$maxccr Median=$medianccr Total=$totalccr"
    
    # Calculate number of context switches per PE
    # (Multiply by two because we count each time a PE's affiliation changes,
    # including it becoming idle and becoming busy again)
    cat _worker_events|grep "LOAD 1"|awk '{rank=$2; cs[rank]+=1} END {for (rank in cs) {print 2*cs[rank]}}'|sort -g > _context_switches
    mediancs=$(sed $(( $(cat _context_switches|wc -l) / 2 ))'q;d' _context_switches)
    meancs=$(cat _context_switches|awk '{sum+=$1} END {print sum/NR}')
    
    #echo "  Context switches per PE: Median=$mediancs Mean=$meancs" 
    
    # Calculate number of processed jobs and response times
    cat $(eval "echo $d/{$firstclient..$lastclient}/log.*")|grep -E "RESPONSE_TIME|TIMEOUT"|sed 's/#//g' > _job_events
    numprocessed=$(cat _job_events|wc -l)
    meanrt=$(cat _job_events|awk '{rt+=$5} END {print rt/NR}')
    
    #echo "  #Processed: $numprocessed"
    #echo "  Mean response time: $meanrt"
    
    # Calculate worker creation occurrences
    cat _worker_events|grep "LOAD 1"|sed 's/[()+#-]//g'|sed 's/:/ /g'|awk '{cs[$5][$6]+=1} END {\
     for (j in cs) {\
      for (i in cs[j]) {\
       occs[cs[j][i]]+=1\
      }\
     }\
     for (i in occs) {\
      print i-1,occs[i]\
     }\
    }'> _worker_creation_occurrences
    
    # Transform occurrences into a cumulative distribution function
    sumoccs=$(cat _worker_creation_occurrences|awk '{sum+=$2} END {print sum}')
    cat _worker_creation_occurrences|awk '{prob+=$2/'$sumoccs'; print $1,prob}' > _worker_creation_cdf
    
    # Report calculated measures
    echo -ne '"'${label}'"'" $medianccr $maxccr $totalccr $mediancs $meancs $numprocessed $meanrt "
    # Report CDF at different points
    for i in $cdf_eval_points; do
        prob=$(cat _worker_creation_cdf|awk '$1 == '$(($i+1))' {print $2}')
        echo -ne "$prob "
    done
    # Line break
    echo ""
    
done
    
 
