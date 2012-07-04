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

var system = require('system'), fs = require("fs");

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
	var maxtimeOutMillis = timeOutMillis ? timeOutMillis : 3001, //< Default Max Timout is 3s
	start = new Date().getTime(),
	condition = false,
	interval = setInterval(function() {
		if ( (new Date().getTime() - start < maxtimeOutMillis) && !condition ) {
			// If not time-out yet and condition not yet fulfilled
			condition = (typeof(testFx) === "string" ? eval(testFx) : testFx()); //< defensive code
		} else {
			if (!condition) {
				// If condition still not fulfilled (timeout but condition is 'false')
				console.log("'waitFor()' timeout");
				phantom.exit(1);
			} else {
				// Condition fulfilled (timeout and/or condition is 'true')
				//console.log("'waitFor()' finished in " + (new Date().getTime() - start) + "ms.");
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

var page = require('webpage').create();

// Reappropriate console.log() calls from within the Page context to be our test output. This way we can
// use this for clean YAML output but allow errors to go to stderr or stdout or wherever phantomjs
// wants to send it without fear of mangling our YAML.
page.onConsoleMessage = function(msg) {
	fs.write(system.args[2], msg, 'a');
};

page.open(system.args[1], function(status) {
    if (status !== "success") {
        console.log("Could not open tests file");
        phantom.exit(1);
    } else {
        waitFor(function(){
            return page.evaluate(function(){
                var el = document.getElementById('qunit-testresult');
                if (el && el.innerText.match('completed')) {
                    return true;
                }
                return false;
            });
        }, function(){
            page.evaluate(function() {
								console.log(QUnited.collectedTestResultsAsYaml());
                return 10000;
            });
            phantom.exit(0);
        });
    }
});
