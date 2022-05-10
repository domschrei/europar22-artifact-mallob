#!/bin/bash

bash fetch_jemalloc.sh

unzip jemalloc.zip
cd jemalloc
./configure
make
