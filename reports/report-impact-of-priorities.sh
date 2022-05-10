#!/bin/bash

set -e

basedir="$1"

if [ ! -d "$basedir" ]; then
    echo "No valid directory provided."
    exit 1
fi

calldir="$(pwd)"
cd "$basedir"

mkdir -p data

# Extract program options from logs of rank zero
options=$(cat 0/log.0|head -10|grep "Program options")
# Extract number of clients from the program options
numclients=$(echo $options|grep -oE " -c=[0-9]+ "|grep -oE "[0-9]+")
# Find out which is the highest process rank
lastclient=$(echo */|tr ' ' '\n'|grep -E '^[0-9]+/$'|sort -g|tail -1|sed 's,/,,g')
# Calculate the rank of the first client 
firstclient=$(($lastclient - $numclients + 1))

# Gather the used priorities
echo "Prio" > data/priorities/priorities
for i in $(seq 0 $(($numclients-1))); do
    cat "${calldir}/templates/job-template-priorities.json.$i"|grep priority|grep -oE "[0-9\.]+" >> data/priorities/priorities
done

echo "$numclients priority streams found."

# Collect mean volume of each stream:
# We compute for each job the average volume it was assigned
# over time. In the end, we aggregate for each stream the
# average assigned volume for all jobs in the stream, 
# weighted by the jobs' run times.
echo "MeanVol" > data/priorities/volumes
cat */log.*|grep ":0 : update v="|awk '{print $1,$3,$6}'|sed 's/[#:v=]/ /g'|awk '{\
 t=$1; id=$2; v=$4; \
 if (lastvol[id] != 0 && t > lasttime[id]) {\
  period = t - lasttime[id]; \
  ratio = period/(period+sumtime[id]); \
  meanvol[id] = ratio*lastvol[id] + (1-ratio)*meanvol[id]; \
  sumtime[id] += period;
 }\
 lastvol[id] = v; lasttime[id] = t;\
} END {\
 for (id in meanvol) {\
  stream = int(id / 100000);\
  v = meanvol[id]; t = sumtime[id];\
  ratio = t/(t+T[stream]);\
  V[stream] = ratio*v + (1-ratio)*V[stream];\
  T[stream] += t;\
 }\
 for (stream in V) {print V[stream]}\
}' >> data/priorities/volumes

# Collect response times for each stream
echo "MeanRT[s]" > data/priorities/times
for rank in $(seq $firstclient $lastclient); do
    cat $rank/log.*|grep RESPONSE_TIME|awk '{print $4,$5}'|sed 's/#//g'|awk '\
    {\
     id=$1; t=$2;\
     stream = int(id / 100000);\
     if (id - 100000*stream <= 80) {\
      sums += t; nums += 1;\
     }\
    } END {\
     print((sums + (80-nums)*300) / 80)\
    }'
done >> data/priorities/times

paste data/priorities/{priorities,volumes,times} |column -t

# Create files for plotting
paste data/priorities/{priorities,volumes} > data/priorities/volume_per_prio
paste data/priorities/{priorities,times} > data/priorities/time_per_prio

# Plot
cd "$calldir"
reports/plot-impact-of-priorities.sh $@
