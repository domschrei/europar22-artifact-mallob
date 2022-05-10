#ifndef _kissat_h_INCLUDED
#define _kissat_h_INCLUDED

typedef struct kissat kissat;

// Default (partial) IPASIR interface.

const char *kissat_signature (void);
kissat *kissat_init (void);
void kissat_add (kissat * solver, int lit);
int kissat_solve (kissat * solver);
int kissat_value (kissat * solver, int lit);
void kissat_release (kissat * solver);

void kissat_set_terminate (kissat * solver,
			   void *state, int (*terminate) (void *state));

// Additional API functions.

void kissat_terminate (kissat * solver);
void kissat_reserve (kissat * solver, int max_var);

const char *kissat_id (void);
const char *kissat_version (void);
const char *kissat_compiler (void);

const char *kissat_copyright (void);
void kissat_build (const char *line_prefix);
void kissat_banner (const char *line_prefix, const char *name_of_app);

int kissat_get_option (kissat * solver, const char *name);
int kissat_set_option (kissat * solver, const char *name, int new_value);

int kissat_has_configuration (const char *name);
int kissat_set_configuration (kissat * solver, const char *name);

void kissat_set_conflict_limit (kissat * solver, unsigned);
void kissat_set_decision_limit (kissat * solver, unsigned);

void kissat_print_statistics (kissat * solver);



// *** API for Mallob ***

// Sets a function to be called whenever kissat learns a clause no longer than the specified max. size.
// The function is called with the provided state and the size and glue value of the learnt clause.
// The clause itself is stored in the provided buffer before the function is called.
void kissat_set_clause_export_callback (kissat * solver, void *state, int *buffer, unsigned max_size, void (*consume) (void *state, int size, int glue));

// Sets a function which kissat may call to import a clause from another solver. The function is called
// with the provided state and expects a literal buffer (or zero), the clause size, and the glue value as out parameters.
// If no clause is available, the function must return clause == 0.
void kissat_set_clause_import_callback (kissat * solver, void *state, void (*produce) (void *state, int **clause, int *size, int *glue));

// Basic "external" statistics struct with some interesting properties of kissat's search.
struct kissat_statistics {unsigned long propagations; unsigned long decisions; unsigned long conflicts; unsigned long restarts;};
// Get the statistics of kissat's current search. Not thread-safe, but only reading, i.e., 
// may (rarely) return improper values.
struct kissat_statistics kissat_get_statistics (kissat * solver);

// Provides to kissat an array of variable phase values. lookup[i] corresponds to external variable i 
// and should be 1, -1, or 0. Kissat may lookup this value for a variable and use the sign to decide
// on the variable's initial phase. The array must be valid during the entire search procedure.
void kissat_set_initial_variable_phases (kissat * solver, signed char *lookup, int size);

// TODO get branching literal: use kissat_next_decision_variable in decide.h ?

#endif
