#!/bin/bash

set -e

# Download formulae one by one
wget --content-disposition -i sc2020-main.uri

# For each downloaded compressed file:
for f in *.cnf.xz; do 
    echo "$f"
    
    # Fix for older versions of wget: remove prefix of
    # the original filename (i.e., 32-digit hex number)
    if echo $f|grep -qE "^[0-9a-f]{32}-.*"; then
        destf=$(echo $f|cut -c 34-)
        mv $f $destf
        f=$destf
    fi
    
    # Decompress file
    unxz "$f"
done
