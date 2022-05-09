#!/bin/bash

rm archive.tar.gz* 2>/dev/null
wget https://dominikschreiber.de/archive.tar.gz
output=$(tar xzvf archive.tar.gz)
dir=$(echo $output|head -1|awk '{print $1}')

rm logs/latest 2>/dev/null
ln -s "$(pwd)/$dir" logs/latest
