<img src="http://i.imgur.com/NIoQy.png" width="150px" />

QUnited is a tool to run headless JavaScript tests with QUnit.

Tests are run with PhantomJS if available, otherwise Rhino (Java) is used. Give it a try and let me know if you have any feedback.

## Installation

```
$ gem install qunited
```

## Running Tests

Add the QUnited Rake task to your Rakefile.

```ruby
require 'qunited/rake_task'

QUnited::RakeTask.new do |t|
  t.source_files_pattern = 'lib/js/**/*.js'
  t.test_files_pattern = 'test/js/**/*.js'
end
```

Source and test files can also be configured as an array of file names. This may be desirable for source files since the order of their execution is often important. A glob pattern may not order the files correctly but configuring the task with an array can guarantee they are executed in the correct order.

Note that all JavaScript dependencies will have to be loaded with source files. They will often need to be loaded before your own code so using an array to configure source files may be appropriate.

```ruby
require 'qunited/rake_task'

QUnited::RakeTask.new do |t|
  t.source_files = ['lib/js/jquery.js', 'lib/js/my_utils.js', 'lib/js/my_app.js']
  t.test_files = ['test/js/test_my_utils.js', 'test/js/test_my_app.js']
end
```

Note that you can also use an array to configure the test files but a glob pattern is usually more convenient since test files usually do not need to be loaded in a particular order.

## Dependencies

- PhantomJS

OR

- Java (version 1.1 minimum)

PhantomJS is preferred since it uses real WebKit and is faster. Running Rhino on Java should be considered a fallback.

## Credits

QUnited builds on the following projects:

[QUnit](https://github.com/jquery/qunit/) is a nice little JavaScript testing library and is, of course, central to what this project does.

[PhantomJS](http://phantomjs.org/) is a headless WebKit with JavaScript API.

[Rhino](http://www.mozilla.org/rhino/) is a JavaScript interpreter that runs on the JVM.

[Envjs](http://www.envjs.com/) is a simulated browser environment written in JavaScript.

## License

QUnited is MIT licensed
