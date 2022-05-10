
This is a **fork** of Kissat. It extends the C interface of Kissat by several functions which are needed for its integration into [Mallob](https://github.com/domschrei/mallob).  
Notably, the new interface features redundant clause export and import, fetching basic statistics, and setting initial variable phases.  
See `src/kissat.h` for the additions to the interface.

The original README of Kissat follows.

<hr/>

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://travis-ci.com/arminbiere/kissat.svg?branch=master)](https://travis-ci.com/arminbiere/kissat)

The Kissat SAT Solver
=====================

Kissat is a "keep it simple and clean bare metal SAT solver" written in C.
It is a port of CaDiCaL back to C with improved data structures, better
scheduling of inprocessing and optimized algorithms and implementation.

Coincidentally "kissat" also means "cats" in Finnish.

Run `./configure && make test` to configure, build and test in `build`.
