/*
 * This contains code that may be placed, by a QUnited driver, on the same page or context where
 * QUnit tests are run. QUnit events are listened for and test results are collected for easier
 * retrieval by other driver code.
 */

var QUnited = QUnited || {};

(function() {

QUnited.util = {};

QUnited.util.dateToString = function(date) {
	if (Object.prototype.toString.call(date) === '[object String]') { return date; }
	function pad(n) { return n < 10 ? '0' + n : n; }
	return date.getUTCFullYear() + '-' + pad(date.getUTCMonth() + 1)+'-' + pad(date.getUTCDate()) + 'T' +
		pad(date.getUTCHours()) + ':' + pad(date.getUTCMinutes()) + ':' + pad(date.getUTCSeconds()) + 'Z';
};

/*
 * Converts the given serializable JavaScript object to a JSON string. Uses the native JSON.stringify.
 */
QUnited.util.jsonStringify = function(object) {
	var jsonString,
			stringifiableTypes,
			toJSONFunctions,
			i;

	// Hack to work around toJSON functions breaking JSON serialization. This most notably can happen
	// when the Prototype library is used. As much as we'd like to just delete these we have to
	// save them to restore them later since tests may be run after this and user code may depend on
	// this stuff.
	stringifiableTypes = [Object, Array, String];
	if (typeof Hash !== 'undefined' && Hash.prototype) { stringifiableTypes.push(Hash); }
	toJSONFunctions = [];

	for (i = 0; i < stringifiableTypes.length; i++) {
		if (stringifiableTypes[i].prototype.toJSON) {
			toJSONFunctions[i] = stringifiableTypes[i].prototype.toJSON;
			delete stringifiableTypes[i].prototype.toJSON;
		} else {
			toJSONFunctions[i] = undefined;
		}
	}

	// The 3rd argument here adds spaces to the generated JSON string. This is necessary
	// for YAML parsers that are not compliant with YAML 1.2 (the version where YAML became
	// a true superset of JSON).
	jsonString = JSON.stringify(object, null, 1);

	// Restore any toJSON functions we removed earlier
	for (i = 0; i < toJSONFunctions.length; i++) {
		if (toJSONFunctions[i]) {
			stringifiableTypes[i].prototype.toJSON = toJSONFunctions[i];
		}
	}

	return jsonString;
};


/* Test results that should be output to be picked up by the formatter, for live result updates
 * while tests are still running. Not all runners may be able to do live updates but keeping this
 * up to date enables that in case they are able to.
 */
QUnited.testResultsPendingOutput = [];

/*
 * Flag to indicate whether all of the QUnit tests have completed. This is set to true with the
 * QUnit.done callback.
 */
QUnited.testsHaveCompleted = false;

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

	QUnit.done(function() {
		QUnited.testsHaveCompleted = true;
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
	return QUnited.util.jsonStringify(QUnited.collectedTestResults());
};

})();
