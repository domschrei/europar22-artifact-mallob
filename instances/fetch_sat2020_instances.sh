#!/bin/bash

set -e

wget https://satcompetition.github.io/2020/downloads/sc2020-main.uri
wget --content-disposition -i sc2020-main.uri

for f in *.cnf.xz; do 
    echo "$f"
    unxz "$f"
done
