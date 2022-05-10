#!/bin/bash


if [ ! -d jemalloc-5.2.1 ]; then
    bash fetch_jemalloc.sh
    unzip jemalloc.zip
fi
cd jemalloc-5.2.1
./autogen.sh
make
