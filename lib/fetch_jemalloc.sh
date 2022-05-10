#!/bin/bash

if [ ! -f jemalloc.zip ]; then
    wget https://github.com/jemalloc/jemalloc/archive/refs/tags/5.2.1.zip -O jemalloc.zip
fi
