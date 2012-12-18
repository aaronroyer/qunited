<img src="http://i.imgur.com/NIoQy.png" width="150px" />

QUnited is a tool to run headless JavaScript tests with QUnit.

Tests are run with PhantomJS if available, otherwise Rhino (Java) is used. Give it a try and let me know if you have any feedback.

## Installation

Install with RubyGems.

```
$ gem install qunited
```

If you are using Bundler you can add QUnited to your Gemfile. With Rails add QUnited to the test and development groups.

```ruby
# In Gemfile
gem 'qunited'
```

```ruby
# With Rails
group :test, :development do
  gem 'qunited'
end
```


## Configuration

Add the QUnited Rake task to your Rakefile. Specify your source and test JavaScript files.

```ruby
require 'qunited/rake_task'

QUnited::RakeTask.new do |t|
  t.source_files = ['lib/js/jquery.js', 'lib/js/my_app_1.js', 'lib/js/my_app_2.js']
  t.test_files_pattern = 'test/js/**/*.js'
end
```

Source and test files can be configured either as an array of file names or a glob pattern (using the ```_pattern``` version). Using an array is usually desirable for source files since the order of their execution is often important. Note that all JavaScript dependencies will have to be loaded with source files, in the correct order, to match your production environment.

You can also use an array to configure the test files but a glob pattern might be more convenient since test files usually do not need to be loaded in a particular order.

### Specifying a driver

QUnited uses various drivers to set up the environment the tests run in (see below for more details). By default it tries to Just Work and find an available driver to use. You may want to lock down the driver (recommended) so your tests are consistent. To do this add a bit more configuration to the Rake task.

```ruby
QUnited::RakeTask.new do |t|
  t.source_files = ['lib/js/jquery.js', 'lib/js/my_app']
  t.test_files_pattern = 'test/js/**/*.js'
  t.driver = :phantomjs # Always use PhantomJS to run tests. Fail if it's not available.
end
```

Available drivers are ```:phantomjs``` and ```:rhino```. If no driver is specified QUnited will run tests with the best available driver, looking for them in that order.

## Running tests

Once the Rake task is configured as described above, run tests like this:

```
$ rake qunited
```

You should get output similar to minitest or Test::Unit

```
$ rake qunited
qunited --driver phantomjs lib/js/jquery-1.4.2.js lib/js/helper.js test/js/app.js -- test/js/test_app.js

# Running JavaScript tests with PhantomJS:

.............

Finished in 0.009 seconds, 1444.44 tests/s, 7777.78 assertions/s.

13 tests, 70 assertions, 0 failures, 0 errors, 0 skips
```

You can change the name of the task...

```ruby
QUnited::RakeTask.new('test:js') do |t|
  # ...
end
```
and run accordingly.

```
$ rake test:js
```

### Running tests in your browser

If you've used QUnit before you've probably run tests in a browser. This is a lot of fun and makes for super quick development.

Run this rake task to start a server that serves up all of your specified source and test JavaScript in the standard QUnit test runner.

```
$ rake qunited:server
```

Then visit http://localhost:3040 in your browser and there they are.

<img src="http://i.imgur.com/o6Gx8.png" width="500px" />

If you specified your own task name then just append ':server' to the end. So if your task name is ```test:js``` then run the server with the following.
```
$ rake test:js:server
```

If the default port of 3040 doesn't suit you then choose one you like.
```ruby
QUnited::RakeTask.new('test:js') do |t|
  t.server_port = 8888
  # ...
end
```

## Drivers

A JavaScript interpreter with browser APIs is necessary to run tests. Various drivers are provided to interface with programs to set up this environment.

### PhantomJS

PhantomJS is a headless WebKit. It is fast and provides an accurate browser environment (since it _is_ a browser).

Find out how to install it [here](http://phantomjs.org/) or just ```brew install phantomjs``` if you have Homebrew.

This driver is considered available if the ```phantomjs``` executable is on your $PATH.

### Rhino + Envjs

Rhino is a JavaScript interpreter that runs on the JVM. Envjs provides a simulated browser environment in Rhino. Rhino+Envjs should be considered a fallback since it is slower and has some minor incompatibility with most browsers. However, most tests will run fine.

Install Java 1.1 or greater to make this work.

This driver is considered available if you have Java 1.1 or greater and the ```java``` executable is on your $PATH.

## Credits

QUnited builds on the following projects:

[QUnit](https://github.com/jquery/qunit/) is a nice little JavaScript testing library and is, of course, central to what this project does.

[PhantomJS](http://phantomjs.org/) is a headless WebKit with JavaScript API.

[Rhino](http://www.mozilla.org/rhino/) is a JavaScript interpreter that runs on the JVM.

[Envjs](http://www.envjs.com/) is a simulated browser environment written in JavaScript.

## License

QUnited is MIT licensed
