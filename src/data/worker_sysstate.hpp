
#pragma once

#include "comm/sysstate.hpp"

#define SYSSTATE_BUSYRATIO 0
#define SYSSTATE_COMMITTEDRATIO 1
#define SYSSTATE_NUMJOBS 2
#define SYSSTATE_GLOBALMEM 3
#define SYSSTATE_NUMHOPS 4
#define SYSSTATE_SPAWNEDREQUESTS 5
#define SYSSTATE_NUMDESIRES 6
#define SYSSTATE_NUMFULFILLEDDESIRES 7
#define SYSSTATE_SUMDESIRELATENCIES 8

typedef SysState<9> WorkerSysState;
