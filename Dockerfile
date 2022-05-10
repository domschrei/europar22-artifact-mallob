FROM ubuntu:20.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y cmake libopenmpi-dev build-essential

# cmake zlib1g-dev libopenmpi-dev unzip xz-utils build-essential cmake wget gdb

# Fetch and build SAT solvers
RUN cd lib && bash fetch_and_build_sat_solvers.sh kcly && cd ..

# Fetch and build jemalloc
RUN cd lib && bash fetch_and_build_jemalloc.sh && cd ..

# Build Mallob
RUN mkdir build
RUN cd build && cmake -DCMAKE_BUILD_TYPE=RELEASE -DMALLOB_ASSERT=1 -DMALLOB_USE_ASAN=0 -DMALLOB_USE_JEMALLOC=1 -DMALLOB_JEMALLOC_DIR=lib/jemalloc-5.2.1/lib -DMALLOB_LOG_VERBOSITY=4 .. && make && cd ..
