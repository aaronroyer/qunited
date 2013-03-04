/*
 * Runs QUnit tests in PhantomJS and outputs test result data, in JSON format, to stdout.
 *
 * Tokens are placed around each test result to allow them to be parsed individually. The tokens
 * match the constants in QUnited::Driver::ResultsCollector.
 *
 * Usage:
 *   phantomjs runner.js PATH_TO_TESTS_HTML_PAGE
 */

var system = require('system'),
    webpage = require('webpage');

if (system.args.length < 2) {
  console.log('No tests file specified');
  phantom.exit(1);
}

var page = webpage.create(),
    testsHtmlFile = system.args[1],
    config = {
      resultsCheckInterval: 200,        // Check for new results at this interval
      testsCompletedCheckInterval: 100, // Check for all tests completing at this interval
      testsTimeout: 10001               // Time out and indicate error after this many millis
    };

/*
 * Writes any collected QUnit results that are pending output to stdout (this is done with
 * console.log in PhantomJS).
 *
 * Tokens are placed around each test result to allow them to be parsed out later. Note that the
 * tokens must match the constants in QUnited::Driver::ResultsCollector.
 *
 * JSON.stringify must be called in the context of the page to properly serialize null values in
 * results. If it is called here in the PhantomJS interpreter code then null values are serialized
 * as empty strings. Finding out exactly why this happens would take more investigation. For now
 * it seems that stringifying on the page is a decent solution, though it is slightly less robust
 * since JSON serialization may be tampered with in user code.
 */
function writePendingTestResults() {
  var serializedResults = page.evaluate(function() {
    var pendingResults = [];
    while (QUnited.testResultsPendingOutput.length > 0) {
      pendingResults.push(JSON.stringify(QUnited.testResultsPendingOutput.shift(), null, 1));
    }
    return pendingResults;
  });

  var i, output;
  for (i = 0; i < serializedResults.length; i++) {
    output = 'QUNITED_TEST_RESULT_START_TOKEN';
    output += serializedResults[i];
    output += 'QUNITED_TEST_RESULT_END_TOKEN';
    console.log(output);
  }
}

/*
 * Executes the given function once all tests have completed. If a timeout occurs then exit
 * with a status code of 1.
 */
function whenTestsHaveCompleted(fn) {
  var start = new Date().getTime(),
      testsHaveCompleted = false,
      interval = setInterval(function() {
        if ( (new Date().getTime() - start < config.testsTimeout) && !testsHaveCompleted ) {
          testsHaveCompleted = page.evaluate(function() { return QUnited.testsHaveCompleted; });
        } else {
          if (testsHaveCompleted) {
            fn();
            clearInterval(interval);
          } else {
            // Tests took too long
            console.log("ERROR: Timeout waiting for tests to complete");
            phantom.exit(1);
          }
        }
      }, config.testsCompletedCheckInterval);
};

/*
 * Open the HTML page that contains all of our QUnit tests. As it is running, check for collected
 * test results and output them if we have any. Also check whether tests have completed. Once they
 * have completed, output any remaining results and exit.
 */
page.open(testsHtmlFile, function(status) {
    if (status !== "success") {
        console.log("Could not open tests file");
        phantom.exit(1);
    } else {
        setInterval(writePendingTestResults, config.resultsCheckInterval);

        whenTestsHaveCompleted(function() {
            writePendingTestResults();
            phantom.exit(0);
        });
    }
});
