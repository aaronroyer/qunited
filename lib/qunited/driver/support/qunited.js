var QUnited = QUnited || {};

(function() {

QUnited.util = {};
QUnited.util.dateToString = function(date) {
	if (Object.prototype.toString.call(date) === '[object String]') { return date; }
	function pad(n) { return n < 10 ? '0' + n : n; }
	return date.getUTCFullYear() + '-' + pad(date.getUTCMonth() + 1)+'-' + pad(date.getUTCDate()) + 'T' +
		pad(date.getUTCHours()) + ':' + pad(date.getUTCMinutes()) + ':' + pad(date.getUTCSeconds()) + 'Z';
};

QUnited.startCollectingTestResults = function() {
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
};

QUnited.collectedTestResultsAsYaml = function() {
	var modules = [];

	// Make a modules array for outputing results
	Object.keys(QUnited.modulesMap).forEach(function(key) {
		var mod = QUnited.modulesMap[key],
				tests = mod.tests;
		modules.push(mod);
		tests.forEach(function(test) {
			// YAML serializer doesn't seem to do dates; make them strings
			test.start = QUnited.util.dateToString(test.start);
			// Convert the duration to a string since the YAML serializer makes them all 0s otherwise
			test.duration = "" + test.duration;
		});
	});

	// Write all the results as YAML
	return YAML.encode(modules);
};

})();
