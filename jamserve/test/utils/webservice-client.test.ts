import { describe, expect, test } from '@jest/globals';
import { WebserviceClient } from '../../src/utils/webservice-client.js';

class ProbeClient extends WebserviceClient {
	async spend(count: number): Promise<void> {
		for (let index = 0; index < count; index++) {
			await this.limit();
		}
	}
}

async function measureSpend(tokensPerInterval: number, count: number): Promise<number> {
	const start = Date.now();
	const client = new ProbeClient(tokensPerInterval, 200, 'test');
	await client.spend(count);
	return Date.now() - start;
}

describe('WebserviceClient rate limit', () => {
	test('spaces requests out over the declared interval', async () => {
		expect(await measureSpend(1, 4)).toBeGreaterThanOrEqual(500);
	});

	test('lets a burst up to the declared tokens through at once', async () => {
		expect(await measureSpend(4, 4)).toBeLessThan(100);
	});

	test('throttles the requests after the burst', async () => {
		expect(await measureSpend(2, 6)).toBeGreaterThanOrEqual(400);
	});
});
