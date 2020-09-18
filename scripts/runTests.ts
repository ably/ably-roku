import * as rokuDeploy from 'roku-deploy';
import * as path from 'path';
import * as rooibos from 'rooibos-cli';

import { util } from './util';

const ROOT_DIR = './';
const OUT_DIR = './out/stagingTests/';

(async () => {
	// Move the files into a staging folder to me modified for tests
	const stagingFolderPath = await rokuDeploy.prepublishToStaging({
		rootDir: ROOT_DIR,
		outDir: OUT_DIR,
		files: [
			{ "src": "./exampleChannel/**/*", "dest": "./" },
			{ "src": "./source/**/*", "dest": "./" },
			{ "src": "./tests/**/*", "dest": "./" }
		],
		retainStagingFolder: true
	});

	await processFilesForTesting(stagingFolderPath)
})().catch();

async function processFilesForTesting(stagingFolderPath: string) {
	const manifestPath = path.join(stagingFolderPath, 'manifest');

	const recordCodeCoverage = util.getEnvSetting('CODE_COVERAGE', false);
	console.log(`CODE_COVERAGE=${recordCodeCoverage}`);

	const fastFail = util.getEnvSetting('FAIL_FAST', false);
	console.log(`FAIL_FAST=${fastFail}`);

	const showFailuresOnly = util.getEnvSetting('SHOW_FAILURES_ONLY', true);
	console.log(`SHOW_FAILURES_ONLY=${showFailuresOnly}`);

	const config = rooibos.createProcessorConfig({
		projectPath: stagingFolderPath,
		sourceFilePattern: [
			'**/*.brs',
			'**/*.xml',
			'!**/tests/**/*.*',
			'!**/tests',
			'!**/rooibosDist.brs',
			'!**/rooibosFunctionMap.brs',
			'!**/TestsScene.brs'
		],
		testsFilePattern: [
			'**/*.spec.brs',
			'!**/rooibosDist.brs',
			'!**/rooibosFunctionMap.brs',
			'!**/TestsScene.brs'
		],
		fastFail: fastFail,
		showFailuresOnly: showFailuresOnly,
		isRecordingCodeCoverage: recordCodeCoverage
	});
	const processor = new rooibos.RooibosProcessor(config);
	await processor.processFiles();
}

// Needed to avoid linter from thinking files are sharing code https://stackoverflow.com/questions/40900791/cannot-redeclare-block-scoped-variable-in-unrelated-files
export {};
