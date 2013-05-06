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
  var output;
  for (var i = 0, len = results.length; i < len; i++) {
    output = 'QUNITED_TEST_RESULT_START_TOKEN';
    output += JSON.stringify(results[i], null, 1);
    output += 'QUNITED_TEST_RESULT_END_TOKEN';
    java.lang.System.out.println(output);
  }
})(QUnited.collectedTestResults());
