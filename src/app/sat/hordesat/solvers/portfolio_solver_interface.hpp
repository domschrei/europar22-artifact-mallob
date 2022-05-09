/*
 * portfolioSolverInterface.h
 *
 *  Created on: Oct 10, 2014
 *      Author: balyo
 * 
 * portfolio_solver_interface.hpp
 * 
 *  Modified by Dominik Schreiber, 2019-*
 */

#ifndef PORTFOLIOSOLVERINTERFACE_H_
#define PORTFOLIOSOLVERINTERFACE_H_

#include <vector>
#include <set>
#include <stdexcept>
#include <functional>
#include <atomic>

#include "app/sat/hordesat/utilities/clause.hpp"
#include "util/logger.hpp"
#include "app/sat/hordesat/sharing/import_buffer.hpp"
#include "solver_statistics.hpp"
#include "solver_setup.hpp"

enum SatResult {
	SAT = 10,
	UNSAT = 20,
	UNKNOWN = 0
};

void updateTimer(std::string jobName);

typedef std::function<void(const Mallob::Clause&, int)> LearnedClauseCallback;
typedef std::function<void(const Mallob::Clause&, int, int, int)> ExtLearnedClauseCallback;

/**
 * Interface for solvers that can be used in the portfolio.
 */
class PortfolioSolverInterface {

protected:
	Logger _logger;
	SolverSetup _setup;

// ************** INTERFACE TO IMPLEMENT **************

public:
	// constructor
	PortfolioSolverInterface(const SolverSetup& setup);

    // destructor
	virtual ~PortfolioSolverInterface() {}

	// Get the number of variables of the formula
	virtual int getVariablesCount() = 0;

	// Get a variable suitable for search splitting
	virtual int getSplittingVariable() = 0;

	// Set initial phase for a given variable
	// Used only for diversification of the portfolio
	virtual void setPhase(const int var, const bool phase) = 0;

	// Solve the formula with a given set of assumptions
	virtual SatResult solve(size_t numAssumptions, const int* assumptions) = 0;

	// Get a solution vector containing lit or -lit for each lit in the model
	virtual std::vector<int> getSolution() = 0;

	// Get a set of failed assumptions
	virtual std::set<int> getFailedAssumptions() = 0;

	// Add a permanent literal to the formula (zero for clause separator)
	virtual void addLiteral(int lit) = 0;

	// Set a function that should be called for each learned clause
	virtual void setLearnedClauseCallback(const LearnedClauseCallback& callback) = 0;

	// Get solver statistics
	virtual void writeStatistics(SolvingStatistics& stats) = 0;

	// Diversify your parameters (seeds, heuristics, etc.) according to the seed
	// and the individual diversification index given by getDiversificationIndex().
	virtual void diversify(int seed) = 0;

	// How many "true" different diversifications do you have?
	// May be used to decide when to apply additional diversifications.
	virtual int getNumOriginalDiversifications() = 0;

	virtual bool supportsIncrementalSat() = 0;
	virtual bool exportsConditionalClauses() = 0;

protected:
	// Interrupt the SAT solving, solving cannot continue until interrupt is unset.
	virtual void setSolverInterrupt() = 0;

	// Resume SAT solving after it was interrupted.
	virtual void unsetSolverInterrupt() = 0;

    // Suspend the SAT solver DURING its execution (ASYNCHRONOUSLY), 
	// temporarily freeing up CPU for other threads
    virtual void setSolverSuspend() = 0;

	// Resume SAT solving after it was suspended.
    virtual void unsetSolverSuspend() = 0;

// ************** END OF INTERFACE TO IMPLEMENT **************


// Other methods

public:
	/**
	 * The solver's ID which is globally unique for the particular job
	 * that is being computed on.
	 * Equal to <rank> * <solvers_per_node> + <local_id>.
	 */
	int getGlobalId() {return _global_id;}
	/**
	 * The solver's local ID on this node and job. 
	 */
	int getLocalId() {return _local_id;}
	/**
	 * This number n denotes that this solver is the n-th solver of this type
	 * being employed to compute on this job.
	 * Equal to the global ID minus the number of solvers of a different type.
	 */
	int getDiversificationIndex() {return _diversification_index;}

	void setCurrentCondVarOrZero(int condVarOrZero) {_current_cond_var_or_zero = condVarOrZero;}
	void setExtLearnedClauseCallback(const ExtLearnedClauseCallback& callback);

	void setCurrentRevision(int revision) {_current_revision = revision;}
	int getCurrentRevision() const {return _current_revision;}

	Logger& getLogger() {return _logger;}
	
	const SolverSetup& getSolverSetup() {return _setup;}
	const SolvingStatistics& getSolverStats() {
		writeStatistics(_stats);
		return _stats;
	}
	SolvingStatistics& getSolverStatsRef() {
		return _stats;
	}

	void interrupt();
	void uninterrupt();
	void suspend();
	void resume();
	void setTerminate();


	// Add a learned clause to the formula
	// The learned clauses might be added later or possibly never
	void addLearnedClause(const Mallob::Clause& c);

	// Add a bulk of learned clauses, but only the ones for which conditional returns true
	void addLearnedClauses(const std::vector<Mallob::Clause>& clauses, 
		std::function<bool(const Clause&)> conditional);

	// Within the solver, fetch a clause that was previously added as a learned clause.
	bool fetchLearnedClause(Mallob::Clause& clauseOut, ImportBuffer::GetMode mode = ImportBuffer::ANY);
	std::vector<int> fetchLearnedUnitClauses();


private:
	std::string _global_name;
	std::string _job_name;
	int _global_id;
	int _local_id;
	int _diversification_index;
	std::atomic_int _current_cond_var_or_zero = 0;
	std::atomic_int _current_revision = 0;
	std::atomic_bool _terminated = false;

	SolvingStatistics _stats;
	ImportBuffer _import_buffer;
};

// Returns the elapsed time (seconds) since the currently registered solver's start time.
double getTime();

#endif /* PORTFOLIOSOLVERINTERFACE_H_ */
