// Runs QUnit tests with Envjs and outputs test results as
// an array of data serialized in YAML format.
//
// The first argument should be the lib directory containing JavaScript dependencies. The second
// argument is the file to use for test results output. The next arguments are source JavaScript
// files to test, until "--" is encountered. After the "--" the rest of the arguments are QUnit
// test files.
//
// Example:
//   java -jar js.jar -opt -1 qunit-runner.js libdir outfile.yaml source.js -- test1.js test2.js
//                                            ^ our args start here

var QUnited = { sourceFiles: [], testFiles: [] };

(function(args) {
	var libDir = args.shift();
	QUnited.outputFile = args.shift();

	['env.rhino.js', 'qunit.js', 'yaml.js'].forEach(function(lib) {
		load(libDir + '/' + lib);
	});

	var readingSource = true;
	args.forEach(function(arg) {
		if (arg === '--') {
			readingSource = false; // Now reading tests
		} else {
			(readingSource ? QUnited.sourceFiles : QUnited.testFiles).push(arg);
		}
	});

	// QUnit config
	QUnit.init();
	QUnit.config.blocking = false;
	QUnit.config.autorun = true;
	QUnit.config.updateRate = 0;

	// Various state we'll need while running the tests
	QUnited.moduleMap = {};
	QUnited.currentTestFile = null; // Set when loading files, see below
	var currentModule, currentTest;

	///// Listen for QUnit events during tests

	QUnit.testStart(function(data) {
		currentTest = {
			name: data.name,
			failures: [],
			start: new Date(),
			assertions: 0,
			file: QUnited.currentTestFile
		};

		var moduleName = data.module || "(no module)",
				module = QUnited.moduleMap[moduleName];
		if (!module) {
			module = {name: moduleName, tests: []};
			QUnited.moduleMap[moduleName] = module;
		}
		module.tests.push(currentTest);
	});

	QUnit.testDone(function(data) {
		currentTest.duration = ((new Date()).getTime() - currentTest.start.getTime()) / 1000;
		currentTest.failed = data.failed;
		currentTest.total = data.total;
	});

	/*
	 * Called on every assertion AND whenever we have an expect(num) fail. You cannot tell this
	 * apart from an assertion (even though you could make a good guess) with certainty so just
	 * don't worry about it as it will only throw assertions count off on a failing test.
	 */
	QUnit.log(function(data) {
		currentTest.assertions++;
		if (!data.result) {
			currentTest.failures.push({
				message: data.message,
				actual: data.actual,
				expected: data.expected,
				test_name: currentTest.name // Ruby style, since we're making YAML
			});
		}
	});

})(Array.prototype.slice.call(arguments, 0));

// Load source files under test
QUnited.sourceFiles.forEach(function(file) {
	load(file);
});

// Load test files
QUnited.testFiles.forEach(function(file) {
	QUnited.currentTestFile = file;
	load(file);
});

(function() {
	var tests, mod, modules = [];

	var ISODateString = function(d) {
		function pad(n) { return n < 10 ? '0' + n : n; }
		return d.getUTCFullYear() + '-' + pad(d.getUTCMonth() + 1)+'-' + pad(d.getUTCDate()) + 'T' +
			pad(d.getUTCHours()) + ':' + pad(d.getUTCMinutes()) + ':' + pad(d.getUTCSeconds()) + 'Z';
	}

	// Make a modules array for outputing results
	for (name in QUnited.moduleMap) {
		mod = QUnited.moduleMap[name]
		modules.push(mod);
		tests = mod.tests;
		tests.forEach(function(test) {
			// YAML serializer doesn't seem to do dates; make them strings
			test.start = ISODateString(test.start);
			// Convert the duration to a string since the YAML serializer makes them all 0s otherwise
			test.duration = "" + test.duration;
		});
	}

	// Write all the results as YAML
	var writer = new java.io.PrintWriter(QUnited.outputFile);
	writer.write(YAML.encode(modules));
	writer.close();
})();
