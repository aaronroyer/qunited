// Runs QUnit tests with Envjs and outputs test results as
// an array of data serialized in YAML format.
//
// The first argument should be the lib directory containing common QUnited dependencies. The second
// argument is the directory containing Rhino driver specific dependencies. The third argument
// is the file to use for test results output. The next arguments are source JavaScript files to
// test, until "--" is encountered. After the "--" the rest of the arguments are QUnit
// test files.
//
// Example:
//   java -jar js.jar -opt -1 runner.js commonlibdir libdir outfile.yaml source.js -- test1.js test2.js
//                                            ^ our args start here

var QUnited = { sourceFiles: [], testFiles: [] };

(function(args) {
	var commonLibDir = args.shift(),
			libDir = args.shift();
	QUnited.outputFile = args.shift();

	load(libDir + '/env.rhino.js');

	['qunit.js', 'yaml.js'].forEach(function(lib) {
		load(commonLibDir + '/' + lib);
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
	QUnited.modulesMap = {};
	QUnited.currentTestFile = null; // Set when loading files, see below
	var currentModule, currentTest;

	///// Listen for QUnit events during tests

	QUnit.testStart(function(data) {
		currentTest = {
			name: data.name,
			assertion_data: [], // Ruby-style, since we'll be reading it with Ruby
			start: new Date(),
			assertions: 0,
			file: QUnited.currentTestFile
		};

		var moduleName = data.module || "(no module)",
				module = QUnited.modulesMap[moduleName];
		if (!module) {
			module = {name: moduleName, tests: []};
			QUnited.modulesMap[moduleName] = module;
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
		currentTest.assertion_data.push(data);
	});

})(Array.prototype.slice.call(arguments, 0));

// Load source files under test
QUnited.sourceFiles.forEach(function(file) {
	load(file);
});

// Load test files
QUnited.testFiles.forEach(function(file) {
	QUnited.currentTestFile = file;

	// There are some tricky issues with loading files in Rhino and properly handling errors in the
	// loaded files (like undefined and syntax errors). Eventually I settled on just loading using
	// Rhino's load() even though it is impossible (in this version, it may be fixed in the future)
	// to know whether or not there was an error in the loaded file. Rhino simply dumps some info to
	// stderr and keeps on going without letting the caller of load() know what happened!
	//
	// Another option is to slurp in the file, eval it, and try/catch the errors and handle them
	// accordingly. But, I found that the slurp and eval approach introduced to many subtle
	// misbehaviors to be worth it.
	//
	// The thing is, if a test file crashes and the tests aren't run then the build will succeed and
	// that is a bad, bad thing. We need to fail the build somehow in this case. A non-ideal solution
	// that I've come up with is to make sure at least one test is run after a file is loaded. A
	// failure when no tests have been written is not unreasonable and it will have the desirable side
	// effect that the build is failed if loading fails and tests are not run.
	load(file);

	// Check that the file had at least one test in it. See above.
	var foundOne = false;
	Object.keys(QUnited.modulesMap).forEach(function(key) {
		var tests = QUnited.modulesMap[key].tests, i, test;
		for (i = 0; test = tests[i++];) {
			if (test.file === file) {
				foundOne = true;
				break;
			}
		};
	});

	if (!foundOne) {
		// Create our own test failure in the default module
		var defaultModuleName = "(no module)",
		    module = QUnited.modulesMap[defaultModuleName];
		if (!module) {
			module = {name: defaultModuleName, tests: []};
			QUnited.modulesMap[defaultModuleName] = module;
		}

		// Push our failed test data into the default module
		module.tests.push({
			name: "Nonexistent test",
			assertion_data: [{
				result: false, message: "Test file did not contain any tests (or there was an error loading it)"
			}],
			start: new Date(), duration: 0,
			assertions: 1, failed: 1, total: 1,
			file: file
		});
	}
});

(function() {
	var modules = [];

	var ISODateString = function(d) {
		function pad(n) { return n < 10 ? '0' + n : n; }
		return d.getUTCFullYear() + '-' + pad(d.getUTCMonth() + 1)+'-' + pad(d.getUTCDate()) + 'T' +
			pad(d.getUTCHours()) + ':' + pad(d.getUTCMinutes()) + ':' + pad(d.getUTCSeconds()) + 'Z';
	}

	// Make a modules array for outputing results
	Object.keys(QUnited.modulesMap).forEach(function(key) {
		var mod = QUnited.modulesMap[key],
				tests = mod.tests;
		modules.push(mod);
		tests.forEach(function(test) {
			// YAML serializer doesn't seem to do dates; make them strings
			test.start = ISODateString(test.start);
			// Convert the duration to a string since the YAML serializer makes them all 0s otherwise
			test.duration = "" + test.duration;
		});
	});


	// Write all the results as YAML
	var writer = new java.io.PrintWriter(QUnited.outputFile);
	writer.write(YAML.encode(modules));
	writer.close();
})();
