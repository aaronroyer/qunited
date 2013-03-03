/*
Portions of this file are from the PhantomJS project from Ofi Labs.

  Copyright (C) 2011 Ariya Hidayat <ariya.hidayat@gmail.com>
  Copyright (C) 2011 Ivan De Marino <ivan.de.marino@gmail.com>

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

  * Redistributions of source code must retain the above copyright
    notice, this list of conditions and the following disclaimer.
  * Redistributions in binary form must reproduce the above copyright
    notice, this list of conditions and the following disclaimer in the
    documentation and/or other materials provided with the distribution.
  * Neither the name of the <organization> nor the
    names of its contributors may be used to endorse or promote products
    derived from this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL <COPYRIGHT HOLDER> BE LIABLE FOR ANY
DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
(INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

var system = require('system'),
    webpage = require('webpage');

/**
 * Wait until the test condition is true or a timeout occurs. Useful for waiting
 * on a server response or for a ui change (fadeIn, etc.) to occur.
 *
 * @param testFx javascript condition that evaluates to a boolean,
 * it can be passed in as a string (e.g.: "1 == 1" or "$('#bar').is(':visible')" or
 * as a callback function.
 * @param onReady what to do when testFx condition is fulfilled,
 * it can be passed in as a string (e.g.: "1 == 1" or "$('#bar').is(':visible')" or
 * as a callback function.
 * @param timeOutMillis the max amount of time to wait. If not specified, 3 sec is used.
 */
function waitFor(testFx, onReady, timeOutMillis) {
  var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3001, //< Default Max Timeout is 3s
  start = new Date().getTime(),
  condition = false,
  interval = setInterval(function() {
    if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
      // If not time-out yet and condition not yet fulfilled
      condition = (typeof(testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
    } else {
      if (!condition) {
        // If condition still not fulfilled (timeout but condition is 'false')
        console.log("ERROR: Timeout waiting for tests to complete");
        phantom.exit(1);
      } else {
        // Condition fulfilled (timeout and/or condition is 'true')
        typeof(onReady) === "string" ? eval(onReady) : onReady(); //< Do what it's supposed to do once the condition is fulfilled
        clearInterval(interval); //< Stop this interval
      }
    }
  }, 100);
};


if (system.args.length < 2) {
  console.log('No tests file specified');
  phantom.exit(1);
}

var page = webpage.create(),
    testsHtmlFile = system.args[1];

/*
 * Write any collected QUnit results that are pending output to stdout (this is done with
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

page.open(testsHtmlFile, function(status) {
    if (status !== "success") {
        console.log("Could not open tests file");
        phantom.exit(1);
    } else {
        setInterval(writePendingTestResults, 200);

        waitFor(function() {
            // Done when all tests have run (the results have been rendered)
            return page.evaluate(function() {
                var el = document.getElementById('qunit-testresult');
                if (el && el.innerText.match('completed')) {
                    return true;
                }
                return false;
            });
        }, function() {
            writePendingTestResults();
            phantom.exit(0);
        });
    }
});
