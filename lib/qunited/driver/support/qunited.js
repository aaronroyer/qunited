var QUnited = QUnited || {};

(function() {

QUnited.util = {};
QUnited.util.dateToString = function(date) {
	if (Object.prototype.toString.call(date) === '[object String]') { return date; }
	function pad(n) { return n < 10 ? '0' + n : n; }
	return date.getUTCFullYear() + '-' + pad(date.getUTCMonth() + 1)+'-' + pad(date.getUTCDate()) + 'T' +
		pad(date.getUTCHours()) + ':' + pad(date.getUTCMinutes()) + ':' + pad(date.getUTCSeconds()) + 'Z';
};

// Test results that should be output to be picked up by the formatter, for status updates
// while tests are still running. Not all runners may be able to do live updates but this
// is there in case they are able to.
QUnited.testResultsPendingOutput = [];

QUnited.startCollectingTestResults = function() {
	// Various state we'll need while running the tests
	QUnited.modulesMap = {};
	QUnited.currentTestFile = null; // Set when loading files, see below
	var currentModule, currentTest;

	///// Listen for QUnit events during tests

	QUnit.testStart(function(data) {
		var moduleName = data.module || "(no module)",
				module = QUnited.modulesMap[moduleName];

		currentTest = {
			name: data.name,
			module_name: moduleName,
			assertion_data: [],
			start: new Date(),
			assertions: 0,
			file: QUnited.currentTestFile
		};

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

		QUnited.testResultsPendingOutput.push(currentTest);
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
};

/* Results as an Array of modules */
QUnited.collectedTestResults = function() {
	return Object.keys(QUnited.modulesMap).map(function(key) {
		return QUnited.modulesMap[key]
	});
};

/* Module results as a JSON string */
QUnited.collectedTestResultsAsJson = function() {
	// The 3rd argument here adds spaces to the generated JSON string. This is necessary
	// for YAML parsers that are not compliant with YAML 1.2 (the version where YAML became
	// a true superset of JSON).
	return JSON.stringify(QUnited.collectedTestResults(), null, 1);
};

})();
