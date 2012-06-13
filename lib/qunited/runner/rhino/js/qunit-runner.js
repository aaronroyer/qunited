// Runs QUnit tests with Envjs
//
// First argument should be the lib directory to find qunited.js, qunit.js, and env.rhino.js.
// All following arguments are paths of the files to test.

/*

var resultsFilesCount = 0;
QUnit.jUnitReport = function(data) {
	print(data.xml);
	print("\n\n");
	var filename = tmpDir + '/results' + resultsFilesCount++ + '.xml';
	var writer = new java.io.PrintWriter(filename);
	writer.write(data.xml);
	writer.close();
};*/
/*
<?xml version="1.0" encoding="UTF-8"?>
<testsuites>
	<testsuite id="0" name="Basics" errors="0" failures="0" hostname="localhost" tests="1" time="0.076" timestamp="2012-06-12T01:16:44Z">
		<testcase name="The source code was loaded" total="1" failed="0" time="0.062">
		</testcase>
	</testsuite>
	<testsuite id="1" name="Math" errors="0" failures="0" hostname="localhost" tests="1" time="0.027" timestamp="2012-06-12T01:16:44Z">
		<testcase name="Addition works" total="2" failed="0" time="0.027">
		</testcase>
	</testsuite>
</testsuites>
*/

(function(args) {
	var libDir = args.shift(),
			tmpFile = args.shift();

	load(libDir + '/qunited.js');
	load(QUNITED.util.join(libDir, 'env.rhino.js'));
	load(QUNITED.util.join(libDir, 'qunit.js'));
	load(QUNITED.util.join(libDir, 'yaml.js'));

	QUNITED.sourceFiles = [];
	QUNITED.testFiles = [];
	QUNITED.tmpFile = tmpFile;

	var readingSource = true;
	args.forEach(function(arg) {
		if (arg === '--') {
			readingSource = false; // Now reading tests
		} else {
			(readingSource ? QUNITED.sourceFiles : QUNITED.testFiles).push(arg);
		}
	});

	// We'll need to keep track of this later
	QUNITED.currentTestFile = null;

	// QUnit config
	QUnit.init();
	QUnit.config.blocking = false;
	QUnit.config.autorun = true;
	QUnit.config.updateRate = 0;

	var modules = {}, currentModule, currentTest, assertionCount,
			results = {failed:0, passed:0, total:0, time:0};

	QUNITED.moduleMap = modules;

	QUnit.testStart(function(data) {
		assertionCount = 0;

		currentTest = {
			name: data.name,
			failures: [],
			start: new Date(),
			assertions: 0,
			file: QUNITED.currentTestFile
		};

		var moduleName = data.module || "(no module)",
				module = modules[moduleName];
		if (!module) {
			module = {name: moduleName, tests: []};
			modules[moduleName] = module;
		}

		if (module) {
			module.tests.push(currentTest);
		}
	});

	QUnit.testDone(function(data) {
		currentTest.duration = ((new Date()).getTime() - currentTest.start.getTime()) / 1000;
		currentTest.failed = data.failed;
		currentTest.total = data.total;
	});

	QUnit.log(function(data) {
		assertionCount++;
		currentTest.assertions++;

		if (!data.result) {
			currentTest.failures.push(data.message);
		}
	});

	QUnit.done(function() {
	});

})(Array.prototype.slice.call(arguments, 0));

// Load source files under test
QUNITED.sourceFiles.forEach(function(file) {
	load(file);
});

// Load test files
QUNITED.testFiles.forEach(function(file) {
	QUNITED.currentTestFile = file;
	load(file);
});

(function() {
	var tests, test, mod, i, modules = [];

	var ISODateString = function(d) {
		function pad(n) {
			return n < 10 ? '0' + n : n;
		}

		return d.getUTCFullYear() + '-' +
			pad(d.getUTCMonth() + 1)+'-' +
			pad(d.getUTCDate()) + 'T' +
			pad(d.getUTCHours()) + ':' +
			pad(d.getUTCMinutes()) + ':' +
			pad(d.getUTCSeconds()) + 'Z';
	}

	// Make a modules array for outputing results
	for (name in QUNITED.moduleMap) {
		mod = QUNITED.moduleMap[name]
		modules.push(mod);
		tests = mod.tests;
		tests.forEach(function(test) {
			// YAML serializer doesn't seem to do dates; make them strings
			test.start = ISODateString(test.start);
			// Convert the duration to a string since the YAML serializer makes them all 0s otherwise
			test.duration = "" + test.duration;
		});
	}

	var writer = new java.io.PrintWriter(QUNITED.tmpFile);
	writer.write(YAML.encode(modules));
	writer.close();
})();
