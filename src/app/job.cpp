
#include <cmath>
#include <limits>
#include "util/assert.hpp"

#include "app/job.hpp"
#include "util/logger.hpp"
#include "util/sys/timer.hpp"
#include "util/permutation.hpp"


Job::Job(const Parameters& params, int commSize, int worldRank, int jobId, JobDescription::Application appl) :
            _params(params), 
            _id(jobId),
            _name("#" + std::to_string(jobId)),
            _appl(appl),
            _time_of_arrival(Timer::elapsedSeconds()), 
            _state(INACTIVE),
            _job_tree(commSize, worldRank, jobId, params.useDormantChildren()), 
            _comm(_id, _job_tree, params.jobCommUpdatePeriod()) {
    
    _growth_period = _params.growthPeriod();
    _continuous_growth = _params.continuousGrowth();
    _max_demand = _params.maxDemand();
    _threads_per_job = _params.numThreadsPerProcess();
}

LocalScheduler Job::constructScheduler(std::function<void(const JobRequest& req, int tag, bool left, int dest)> emitJobReq) {
    LocalScheduler scheduler(_id, _params, _job_tree);
    scheduler.initCallbacks(
        // callback to emit a directed job request message to a specific PE
        [this, emitJobReq](int epoch, int requestedIndex, int rank) {
            JobRequest req(_id, _appl, _job_tree.getRootNodeRank(), 
                _job_tree.getRank(), requestedIndex, Timer::elapsedSeconds(), epoch, -2);
            req.revision = std::max(0, getDesiredRevision());
            LOG_ADD_DEST(V5_DEBG, "RBS EMIT_REQ %s", rank, req.toStr().c_str());
            emitJobReq(req, MSG_REQUEST_NODE_ONESHOT, req.requestedNodeIndex == _job_tree.getLeftChildIndex(), rank);
        },
        // callback to emit a certain, undirected job request message
        [this, emitJobReq](int epoch, int requestedIndex) {
            JobRequest req(_id, _appl, _job_tree.getRootNodeRank(), 
                _job_tree.getRank(), requestedIndex, Timer::elapsedSeconds(), epoch, 0);
            req.revision = std::max(0, getDesiredRevision());
            LOG(V5_DEBG, "RBS EMIT_REQ %s\n", req.toStr().c_str());
            emitJobReq(req, MSG_REQUEST_NODE, req.requestedNodeIndex == _job_tree.getLeftChildIndex(), -1);
        }
    );
    return scheduler;
}

void Job::updateJobTree(int index, int rootRank, int parentRank) {

    if (index == 0) rootRank = -1;
    _name = "#" + std::to_string(_id) + ":" + std::to_string(index);
    _job_tree.update(index, rootRank, parentRank);
}

void Job::commit(const JobRequest& req) {
    assert(getState() != ACTIVE);
    assert(getState() != PAST);
    _commitment = req;
    _balancing_epoch_of_last_commitment = req.balancingEpoch;
    _job_tree.clearJobNodeUpdates();
    updateJobTree(req.requestedNodeIndex, req.rootRank, req.requestingNodeRank);
}

void Job::uncommit() {
    assert(getState() != ACTIVE);
    _commitment.reset();
}

void Job::pushRevision(const std::shared_ptr<std::vector<uint8_t>>& data) {

    _description.deserialize(data);
    _priority = _description.getPriority();
    if (_description.getMaxDemand() > 0) {
        // Set max. demand to more restrictive number
        // among global and job-internal limit
        _max_demand = _max_demand == 0 ? 
            _description.getMaxDemand() // no global max. demand defined
            : std::min(_max_demand, _description.getMaxDemand()); // both limits defined
    }
    
    if (_params.maxLiteralsPerThread() > 0 && _description.getNumFormulaLiterals() > _params.maxLiteralsPerThread()) {
        
        // Solver literal threshold exceeded: reduce number of solvers for this job
        long maxAllowedLiterals = _threads_per_job * _params.maxLiteralsPerThread();
        int optNumThreads = std::floor((float)maxAllowedLiterals / _description.getNumFormulaLiterals());
        _threads_per_job = std::max(1, optNumThreads);
        LOG(V3_VERB, "%s : literal threshold exceeded - cut down #threads to %i\n", toStr(), _threads_per_job);
    }

    _has_description = true;
    _result.reset();
}

void Job::start() {
    assertState(INACTIVE);
    if (_time_of_activation <= 0) _time_of_activation = Timer::elapsedSeconds();
    _time_of_last_limit_check = Timer::elapsedSeconds();
    _volume = std::max(1, _volume);
    _state = ACTIVE;
    LOG(V4_VVER, "%s : new job node starting\n", toStr());
    appl_start();
}

void Job::suspend() {
    assertState(ACTIVE);
    _state = SUSPENDED;
    appl_suspend();
    _job_tree.unsetLeftChild();
    _job_tree.unsetRightChild();
    LOG(V4_VVER, "%s : suspended solver\n", toStr());
    updateVolumeAndUsedCpu(getVolume());
}

void Job::resume() {
    assertState(SUSPENDED);
    _volume = std::max(1, _volume);
    _state = ACTIVE;
    appl_resume();
    LOG(V4_VVER, "%s : resumed solving threads\n", toStr());
    _time_of_last_limit_check = Timer::elapsedSeconds();
}

void Job::terminate() {
    if (_state == ACTIVE) 
        updateVolumeAndUsedCpu(getVolume());

    _state = PAST;
    
    appl_terminate();

    _job_tree.unsetLeftChild();
    _job_tree.unsetRightChild();

    _time_of_abort = Timer::elapsedSeconds();
    LOG(V4_VVER, "%s : terminated\n", toStr());
}

bool Job::isDestructible() {
    assert(getState() == PAST);
    return appl_isDestructible();
}

int Job::getDemand() const {
    
    if (_state != ACTIVE) {
        return _commitment.has_value() ? 1 : 0;
    } 
    
    int commSize = _job_tree.getCommSize();
    int demand; 
    if (_growth_period <= 0) {
        // Immediate growth
        demand = _job_tree.getCommSize();
    } else {
        if (_time_of_activation <= 0) demand = 1;
        else {
            float t = Timer::elapsedSeconds()-_time_of_activation;
            
            // Continuous growth
            float numPeriods = std::min(t/_growth_period, 28.f); // overflow protection
            if (!_continuous_growth) {
                // Discrete periodic growth
                int intPeriods = std::floor(numPeriods);
                demand = 1;
                for (int i = 0; demand < commSize && i < intPeriods; i++) demand = 2*demand+1;
                demand = std::min(commSize, demand);
            } else {
                // d(0) := 1; d := 2d+1 every <growthPeriod> seconds
                demand = std::min(commSize, (int)std::pow(2, numPeriods + 1) - 1);
            }
        }
    }

    // Limit demand if desired
    if (_max_demand > 0) {
        demand = std::min(demand, _max_demand);
    }
    return demand;
}

double Job::getTemperature() const {

    double baseTemp = 0.95;
    double decay = 0.99; // higher means slower convergence

    int age = (int) (Timer::elapsedSeconds()-_time_of_activation);
    double eps = 2*std::numeric_limits<double>::epsilon();

    // Start with temperature 1.0, exponentially converge towards baseTemp 
    double temp = baseTemp + (1-baseTemp) * std::pow(decay, age+1);
    
    // Check if machine precision range is reached, if not reached yet
    if (_age_of_const_cooldown < 0 && _last_temperature - temp <= eps) {
        _age_of_const_cooldown = age;
    }
    // Was limit already reached?
    if (_age_of_const_cooldown >= 0) {
        // indefinitely cool down job by machine precision epsilon
        return baseTemp + (1-baseTemp) * std::pow(decay, _age_of_const_cooldown+1) - (age-_age_of_const_cooldown+1)*eps;
    } else {
        // Use normal calculated temperature
        _last_temperature = temp;
        return temp;
    }
}

JobResult& Job::getResult() {
    if (!_result.has_value()) _result = std::move(appl_getResult());
    JobResult& result = _result.value();
    assert(result.id >= 1);
    return result;
}

bool Job::wantsToCommunicate() {
    if (_state != ACTIVE) return false;
    if (_comm.wantsToAggregate()) return true;
    return appl_wantsToBeginCommunication();
}

void Job::communicate() {
    if (_comm.isAggregating()) _comm.beginAggregation();
    else appl_beginCommunication();
}

void Job::communicate(int source, JobMessage& msg) {
    if (_comm.handle(msg)) {
        if (msg.tag == MSG_BROADCAST_RANKLIST && _job_tree.isRoot()) {
            // Check size of job comm compared to scheduler's job volume
            if (_comm.size() != getVolume()) {
                LOG(V1_WARN, "[WARN] %s job tree has size %i/%i\n", toStr(), _comm.size(), getVolume());
            }
        }
    } else {
        appl_communicate(source, msg);
    }
}
