FROM ubuntu:20.04

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt install -y git cmake zlib1g-dev libopenmpi-dev unzip xz-utils build-essential cmake wget libjemalloc-dev libjemalloc2 gdb
    
# Fetch Mallob
RUN git clone https://github.com/domschrei/mallob
WORKDIR mallob
RUN git checkout interface

# Fetch and build SAT solvers
RUN cd lib && bash fetch_and_build_sat_solvers.sh kclgy && cd ..

# Build Mallob
RUN mkdir build
RUN cd build && cmake -DCMAKE_BUILD_TYPE=RELEASE -DMALLOB_ASSERT=1 -DMALLOB_USE_GLUCOSE=1 -DMALLOB_USE_ASAN=0 -DMALLOB_USE_JEMALLOC=1 -DMALLOB_JEMALLOC_DIR=/usr/lib/x86_64-linux-gnu -DMALLOB_LOG_VERBOSITY=3 .. && VERBOSE=1 make -j4 && cd ..
