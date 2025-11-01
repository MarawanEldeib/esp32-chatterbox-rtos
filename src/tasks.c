#include "tasks.h"
#include <assert.h>
#include <stdio.h>

/**
 * @brief TODO 3: Let LED blink for (roughly) delay_ms.
 *
 * @param led	    LED device.
 * @param delay_ms  Delay in milliseconds. Must be a multiple of
 *		    BLINK_PERIOD_MS.
 */
void useless_load(int task_id, const struct gpio_dt_spec *led, int32_t delay_ms)
{
	assert(delay_ms % BLINK_PERIOD_MS == 0 && BLINK_PERIOD_MS % 2 == 0);

	// Let LED blink for (roughly) delay_ms
	for (int32_t d = 0; d < delay_ms; d += BLINK_PERIOD_MS) {
		printf(" Task %d\n", task_id);

		/** Toggle LED ON and OFF to make it blink */
		// Turn LED ON
		gpio_pin_set_dt(led, 1);
		k_busy_wait((BLINK_PERIOD_MS / 2) * 1000); // Half period ON
		
		// Turn LED OFF
		gpio_pin_set_dt(led, 0);
		k_busy_wait((BLINK_PERIOD_MS / 2) * 1000); // Half period OFF
	}
	
	// Ensure LED is OFF after execution
	gpio_pin_set_dt(led, 0);
}

/**
 * @brief TODO 3: Implementation of the chatterbox task
 */
void chatterbox_task(struct task_params *params)
{
	/** Implement the chatterbox task for generic *task_params*.
	 * This consists of:
	 *  - Initializing the GPIO pin for params->led
	 *  - Periodically executing the task by calling *useless_load*
	 *  - Suspending the task until the next cycle
	 */
	
	// Initialize GPIO pin as output
	if (!gpio_is_ready_dt(params->led)) {
		printf("Error: LED device %s is not ready\n", params->led->port->name);
		return;
	}
	
	int ret = gpio_pin_configure_dt(params->led, GPIO_OUTPUT_ACTIVE);
	if (ret < 0) {
		printf("Error: failed to configure LED pin\n");
		return;
	}
	
	// Start the timer for periodic execution
	k_timer_start(params->timer, K_MSEC(params->period_ms), K_MSEC(params->period_ms));
	
	// Main task loop
	while (1) {
		// Execute the task (blink LED)
		useless_load(params->task_id, params->led, params->execution_time_ms);
		
		// Wait for the next period using timer
		k_timer_status_sync(params->timer);
	}
}

/** TODO 3: After correctly setting the GPIO assignments for
 * Task 2 and 3 in boards/esp_wrover_kit_procpu.overlay,
 * uncomment the following lines.
 */
INITIALIZE_TASK(1);
INITIALIZE_TASK(2);
INITIALIZE_TASK(3);
