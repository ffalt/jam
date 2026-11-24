// The current timestamp in whole milliseconds
export function getMilliseconds(): number {
	return Date.now();
}

// Wait for a specified number of milliseconds before fulfilling the returned promise.
export function wait(ms: number): Promise<void> {
	return new Promise(resolve => setTimeout(resolve, ms));
}
