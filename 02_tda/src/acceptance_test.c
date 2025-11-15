#include <math.h>
#include <stdio.h>

#include "acceptance_test.h"

void utilization_bound_test(struct task_params **params, unsigned int task_id,
			    AcceptanceTestResult results[])
{
	double utilization = 0;
	bool accepted = false;

	/*--------------------------------------------------------------------
	 * TODO 1: Implement the Utilization Bound Test from the lecture
	 ---------------------------------------------------------------------*/
	// Calculate total utilization for tasks 0 to task_id (including only accepted tasks)
	for (unsigned int i = 0; i <= task_id; i++) {
		// Only include tasks that were previously accepted (or current task)
		if (i == task_id || results[i].accepted) {
			utilization += (double)params[i]->execution_time_ms / (double)params[i]->period_ms;
		}
	}

	// Calculate the utilization bound: n * (2^(1/n) - 1)
	// n is the number of tasks being considered (task_id + 1, counting accepted tasks)
	unsigned int n = 0;
	for (unsigned int i = 0; i <= task_id; i++) {
		if (i == task_id || results[i].accepted) {
			n++;
		}
	}

	double bound = (double)n * (pow(2.0, 1.0 / (double)n) - 1.0);

	// Task is accepted if utilization is within the bound
	accepted = (utilization <= bound);

	results[task_id].accepted = accepted;
	results[task_id].info.util = utilization;

	printf("Utiliization Test (Task %d): %f (%s)\n", task_id + 1, utilization,
	       accepted ? "accepted" : "rejected");
}

void worst_case_simulation(struct task_params **params, unsigned int task_id,
			   AcceptanceTestResult results[])
{
	int32_t completion_time = 0;
	bool accepted = false;

	/*--------------------------------------------------------------------
	 * TODO 2: Implement the Worst Case Simulation from the lecture
	 ---------------------------------------------------------------------*/
	// Worst-case completion time is calculated by simulating task execution
	// Find the worst-case response time in the first period
	int32_t deadline = params[task_id]->period_ms;

	// Start with execution time of the task itself
	int32_t w_prev = 0;
	int32_t w = params[task_id]->execution_time_ms;

	// Iteratively calculate interference from higher priority tasks
	while (w != w_prev && w <= deadline) {
		w_prev = w;
		w = params[task_id]->execution_time_ms;

		// Add interference from all higher priority accepted tasks
		for (unsigned int i = 0; i < task_id; i++) {
			if (results[i].accepted) {
				// Number of instances of task i that interfere
				int32_t instances = (w_prev + params[i]->period_ms - 1) / params[i]->period_ms;
				w += instances * params[i]->execution_time_ms;
			}
		}
	}

	completion_time = w;
	accepted = (w <= deadline);

	// ___________________________ END _____________________________________
	results[task_id].accepted = accepted;
	results[task_id].info.wcs_result = completion_time;

	printf("Worst Case Simulation (Task %d): %d ms (%s)\n", task_id + 1, completion_time,
	       accepted ? "accepted" : "rejected");
}

void time_demand_analysis(struct task_params **params, unsigned int task_id,
			  AcceptanceTestResult results[])
{
	int32_t t_next = 0;
	bool accepted = false;

	/*--------------------------------------------------------------------
	 * TODO 3: Implement the Time Demand Analysis from the lecture
	 ---------------------------------------------------------------------*/
	// Time-Demand Analysis iteratively calculates the response time
	int32_t deadline = params[task_id]->period_ms;
	int32_t t_prev = 0;
	t_next = params[task_id]->execution_time_ms;

	// Iterate until convergence or deadline is exceeded
	while (t_next != t_prev && t_next <= deadline) {
		t_prev = t_next;
		t_next = params[task_id]->execution_time_ms;

		// Add interference from all higher priority accepted tasks
		for (unsigned int i = 0; i < task_id; i++) {
			if (results[i].accepted) {
				// Calculate ceiling of (t_prev / period_i) to get number of interfering jobs
				int32_t num_jobs = (t_prev + params[i]->period_ms - 1) / params[i]->period_ms;
				t_next += num_jobs * params[i]->execution_time_ms;
			}
		}
	}

	// Task is accepted if the response time is within the deadline
	accepted = (t_next <= deadline);

	results[task_id].accepted = accepted;
	results[task_id].info.tda_result = t_next;

	printf("Time Demand Analysis (Task %d): %d ms (%s)\n", task_id + 1, t_next,
	       accepted ? "accepted" : "rejected");
}

/* Determine if params[task_id] can be scheduled.
 * - params: array of all task parameters (e.g., needed to perform TDA)
 * - task_id: index such that params[task_id] is the task under consideration
 * - results: output parameter yielding the acceptance test result */
void acceptance_test(struct task_params **params, unsigned int task_id,
		     AcceptanceTestResult results[])
{
	/*--------------------------------------------------------------------
	 * TODO 4: Call the above acceptance tests in a suitable order.
	 *  In particular, recall which of these tests are necessary,
	 *  sufficient, or both.
	 *  Ensure that the final value of result->accepted is true if and
	 *  only if the task encoded by params[task_id] can be scheduled.
	 ---------------------------------------------------------------------*/

	// Initialize result as not accepted
	results[task_id].accepted = false;

	// Test order (increasing computational complexity):
	// 1. UBT (O(n)) - SUFFICIENT but NOT necessary
	// 2. TDA (O(n*log(deadline))) - NECESSARY and SUFFICIENT (exact)
	// 3. WCS (O(deadline)) - NECESSARY and SUFFICIENT (exact, but most expensive)

	// 1. Utilization Bound Test - cheapest, sufficient test
	//    If it passes, task is definitely schedulable
	utilization_bound_test(params, task_id, results);
	if (results[task_id].accepted) {
		return; // Definitive acceptance - no need for further tests
	}

	// 2. Time-Demand Analysis - exact test, moderate complexity
	//    This is both necessary and sufficient
	time_demand_analysis(params, task_id, results);
	// TDA gives definitive answer (necessary and sufficient)
	// If accepted or rejected, we have our answer
	// No need for WCS since TDA is exact
}
