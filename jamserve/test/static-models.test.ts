import { describe, expect, test } from '@jest/globals';
import fse from 'fs-extra';
import path from 'node:path';

const modelsWithSourceTypings = [
	'acousticbrainz-rest-data',
	'acoustid-rest-data',
	'coverartarchive-rest-data',
	'discogs-rest-data',
	'lastfm-rest-data',
	'musicbrainz-rest-data',
	'wikidata-rest-data'
];

describe('models shipped in the generated api clients', () => {
	test.each(modelsWithSourceTypings)('static/models/%s.ts is a copy of the source typings', async name => {
		const shipped = await fse.readFile(path.resolve('static/models', `${name}.ts`), 'utf8');
		const source = await fse.readFile(path.resolve('src/modules/audio/clients', `${name}.d.ts`), 'utf8');
		expect(shipped).toEqual(source);
	});
});
