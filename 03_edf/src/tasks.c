#include <assert.h>
#include <stdio.h>

#include "display.h"
#include "tasks.h"

/**
 * @brief Let LED blink for (roughly) delay_ms.
 *
 * @param params    Task parameters
 */
void useless_load_periodic_tasks(struct task_params *params)
{
	assert(params->execution_time_ms % BLINK_PERIOD_MS == 0 && BLINK_PERIOD_MS % 2 == 0);

	// Lock scheduler to avoid time sharing if the deadline of two or multiple tasks is equal
	k_sched_lock();
	for (int32_t d = 0; d < params->execution_time_ms; d += BLINK_PERIOD_MS) {
		printf(" Task %d with deadline %d\n", params->task_id,
		       params->thread->base.prio_deadline);
		gpio_pin_set_dt(params->led, 1);
		k_busy_wait(BLINK_PERIOD_MS * 1000 / 2);
		gpio_pin_set_dt(params->led, 0);
		k_busy_wait(BLINK_PERIOD_MS * 1000 / 2);
	}
	k_sched_unlock();
}

/**
 * @brief Show animation on SSD1306 for one second
 */
void useless_load_aperiodic_tasks()
{
	k_sched_lock();
	for (int32_t d = 0; d < MSEC_PER_SEC; d += BLINK_PERIOD_MS) {
		printf(" Aperiodic task\n");
		ssd1306_print_aperiodic_task();
		k_busy_wait(BLINK_PERIOD_MS * 1000);
	}
	k_sched_unlock();
}

/**
 * @brief Simplified version of z_impl_k_thread_deadline_set
 *
 * Unfortunately, z_impl_k_thread_deadline_set relies on deadlines
 * relative to the CPU cycle counter, while casting the result in
 * int32_t. For our dummy tasks, with periods and latencies in the
 * range of multiple seconds, this will result in frequent overflows
 * that breaks EDF as a consequence.
 *
 * @param thread    thread handle
 * @param deadline  thread deadline in milliseconds
 */
void thread_deadline_set(struct k_thread *thread, int deadline)
{
	/* TODO (Part a): Write a simplified version of z_impl_k_thread_deadline_set
	 * that specified the deadline in milliseconds rather than
	 * in CPU cycle counts.
	 * Hint: You can use k_yield() after updating the deadline
	 * to dequeue the thread from the ready queue. */

	/* Clamp deadline to valid range */
	deadline = CLAMP(deadline, 0, INT_MAX);

	/* Calculate absolute deadline in milliseconds from current uptime */
	int32_t newdl = k_uptime_get_32() + deadline;

	/* Set thread's priority deadline */
	thread->base.prio_deadline = newdl;

	/* Yield to trigger rescheduling */
	k_yield();
}

/**
 * @brief System density test for periodic tasks
 *
 * @params params task specification
 */
bool acceptance_test(struct task_params *params)
{
	static bool acceptance_test_results[CONFIG_NUM_TASKS];

	/* TODO (Part a): The system density test should account for the deferrable server (DS).
	 * That is, we assume the DS is always accepted and the acceptance is solely performed for
	 * periodic tasks. Moreover the acceptance test is called iteratively (see main.c), meaning
	 * that Task i must only account for the previously accepted tasks.
	 *
	 * Your solution should
	 *  - use STRUCT_SECTION_FOREACH for retrieving the task specification of all other tasks
	 *    (see main.c for reference)
	 *  - store the acceptance test result in *acceptance_test_results*
	 * */

	/* Calculate system density: sum of (execution_time / period) for all tasks */
	float system_density = 0.0f;

	/* Iterate through all tasks using STRUCT_SECTION_FOREACH */
	STRUCT_SECTION_FOREACH(task_params, p) {
		/* Include deferrable server in density calculation */
		if (p->type == DEFERRABLE_SERVER) {
			system_density += (float)p->execution_time_ms / (float)p->period_ms;
		}
		/* Include previously accepted periodic tasks (task_id < current task_id) */
		else if (p->type == PERIODIC_TASK && p->task_id < params->task_id &&
			 acceptance_test_results[p->task_id]) {
			system_density += (float)p->execution_time_ms / (float)p->period_ms;
		}
	}

	/* Add current task to density */
	system_density += (float)params->execution_time_ms / (float)params->period_ms;

	/* EDF acceptance test: system density must be <= 1.0 */
	bool accepted = (system_density <= 1.0f);

	/* Store the result */
	acceptance_test_results[params->task_id] = accepted;

	return accepted;
}

/**
 * @brief Dummy task implementation that toggles LED
 */
void periodic_task_implementation(void *p0, void *p1, void *p2)
{
	struct task_params *params = (struct task_params *)p0;

	if (!gpio_is_ready_dt(params->led)) {
		return;
	}
	int ret = gpio_pin_configure_dt(params->led, GPIO_OUTPUT_ACTIVE);
	if (ret < 0) {
		return;
	}

	k_timer_start(params->timer, K_NO_WAIT, K_MSEC(params->period_ms));
	for (int32_t i = 1;; i++) {
		k_timer_status_sync(params->timer);
		thread_deadline_set(params->thread, i * params->period_ms);
		useless_load_periodic_tasks(params);
	}
}

/* TODO (Part b): Configure the button in the DTS overlay and initialize the GPIO driver here.
 * The goal is to release an aperiodic job whenever the button is pressed and to use the deferrable
 * server (as introduced in the lecture) to schedule them. To this end, you have to complete
 * the implementation of
 *  - button_press_callback
 *  - init_button_gpio
 *  - deferrable_server_implementation
 * */

/* Semaphore to signal button press from ISR to deferrable server */
K_SEM_DEFINE(button_sem, 0, 1);

/* Button device specification */
static const struct gpio_dt_spec button_spec = GPIO_DT_SPEC_GET(DT_ALIAS(sw0), gpios);
static struct gpio_callback button_cb_data;

void button_press_callback(const struct device *dev, struct gpio_callback *cb, uint32_t pins)
{
	/* Utilize a suitable synchronization primitive to let the DS know that
	 * the button was pressed. Note that
	 *  - Interrupt service routines (ISRs) are very different from normal threads and many
	 *    kernel APIs behave differently when called from an ISR or from a thread. The
	 *    implementation of this ISR should therefore be as lightweight as possible. For more
	 *    information, see https://docs.zephyrproject.org/latest/kernel/services/interrupts.html
	 *  - Deferrable servers are supposed to yield their execution to the scheduler if there
	 *    are no asynchronous jobs available. Thus, your synchronization primitive must not
	 *    result in busy waiting that may start periodic tasks.
	 * */

	/* Give semaphore to signal button press - this is ISR-safe and non-blocking */
	k_sem_give(&button_sem);
}

int init_button_gpio()
{
	/* TODO: Initialize the GPIO pin to trigger a callback to *button_press_callback* whenever
	 *the button is pressed. For reference, you may want to have a look at:
	 *https://docs.zephyrproject.org/latest/samples/basic/button/README.html */

	int ret;

	/* Check if button device is ready */
	if (!gpio_is_ready_dt(&button_spec)) {
		printf("Error: button device %s is not ready\n", button_spec.port->name);
		return -1;
	}

	/* Configure GPIO pin as input */
	ret = gpio_pin_configure_dt(&button_spec, GPIO_INPUT);
	if (ret != 0) {
		printf("Error %d: failed to configure %s pin %d\n", ret, button_spec.port->name,
		       button_spec.pin);
		return ret;
	}

	/* Configure interrupt on button press (falling edge for active-low) */
	ret = gpio_pin_interrupt_configure_dt(&button_spec, GPIO_INT_EDGE_TO_ACTIVE);
	if (ret != 0) {
		printf("Error %d: failed to configure interrupt on %s pin %d\n", ret,
		       button_spec.port->name, button_spec.pin);
		return ret;
	}

	/* Initialize callback */
	gpio_init_callback(&button_cb_data, button_press_callback, BIT(button_spec.pin));
	gpio_add_callback(button_spec.port, &button_cb_data);

	printf("Button initialized on GPIO%d\n", button_spec.pin);
	return 0;
}

void deferrable_server_implementation(void *p0, void *p1, void *p2)
{
	struct task_params *params = (struct task_params *)p0;

	/* TODO: Implement a deferrable server that replenishes periodically, but
	 * that does not accumulate its budget over multiple cycles. For simplicity,
	 * you may assume the following:
	 *  - Every aperiodic job is identical and wants to run *useless_load_aperiodic_tasks()*
	 *  - The budget of the DS is equal to the budget of one aperiodic job per period
	 * As a starting point, you can likely reuse parts of *periodic_task_implementation*.
	 * */

	/* Initialize button GPIO */
	if (init_button_gpio() < 0) {
		printf("Failed to initialize button GPIO\n");
		return;
	}

	printf("Deferrable Server started (period=%dms, budget=%dms)\n", params->period_ms,
	       params->execution_time_ms);

	/* Start periodic timer */
	k_timer_start(params->timer, K_NO_WAIT, K_MSEC(params->period_ms));

	for (int32_t i = 1;; i++) {
		/* Wait for next period */
		k_timer_status_sync(params->timer);

		/* Set deadline for this period (EDF scheduling) */
		thread_deadline_set(params->thread, i * params->period_ms);

		/* Budget is replenished at the start of each period
		 * No budget accumulation - reset to execution_time_ms each period */
		int32_t budget = params->execution_time_ms;

		/* Check if button was pressed (non-blocking check) */
		if (k_sem_take(&button_sem, K_NO_WAIT) == 0) {
			/* Button was pressed - aperiodic job is available */

			/* Execute aperiodic job only if DS has enough budget */
			if (budget >= (int32_t)MSEC_PER_SEC) {
				printf(" Deferrable Server: Executing aperiodic job\n");
				useless_load_aperiodic_tasks();
				budget -= MSEC_PER_SEC;
			} else {
				printf(" Deferrable Server: Insufficient budget for aperiodic job\n");
				/* Put the semaphore back since we couldn't service the request */
				k_sem_give(&button_sem);
			}
		}

		/* If no job available or no budget, DS yields without consuming budget
		 * The k_timer_status_sync already handles yielding to scheduler */
	}
}

/**
 * @brief Prints current time in seconds
 */
void print_time()
{
	static int time_sec = 0;
	printf("T = %ds:\n", time_sec);
	time_sec++;
}
K_TIMER_DEFINE(time_keeper, print_time, NULL);

/**
 * @brief Initializes periodic timer interrupt to print time in seconds
 */
void start_time_keeper(void)
{
	k_timer_start(&time_keeper, K_NO_WAIT, K_MSEC(1000));
}
