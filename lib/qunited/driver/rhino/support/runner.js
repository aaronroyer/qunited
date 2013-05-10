// Load EnvJs
load(arguments[0]);

// Allow script tags in test document to be eval'd
Envjs({
  scriptTypes: {
    '': true,
    'text/javascript': true
  }
});

// Load up the test document
window.location = arguments[1];

// Print the collected test results to stdout
(function(results) {
  var tests, output, i, j;
  for (i = 0; i < results.length; i++) {
    tests = results[i].tests;
    for (j = 0; j < tests.length; j++) {
      output = 'QUNITED_TEST_RESULT_START_TOKEN';
      output += QUnited.util.jsonStringify(tests[j]);
      output += 'QUNITED_TEST_RESULT_END_TOKEN';
      console.log(output);
    }
  }
})(QUnited.collectedTestResults());
