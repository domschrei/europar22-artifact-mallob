#!/bin/bash

bash fetch_jemalloc.sh

unzip jemalloc.zip
cd jemalloc-5.2.1
./configure
make
