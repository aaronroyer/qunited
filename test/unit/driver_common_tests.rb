# Common driver tests that should pass for any implementation of
# QUnited::Driver::Base. There are also a few utility methods included.
module QUnited::DriverCommonTests
  def test_driver_available
    assert driver_class.available?, 'Driver should be available - if it is not then ' +
      'either the available? method has a bug or you do not have the proper environment ' +
      "to run the driver; check the available? method in the #{driver_class} driver class " +
      'to get an idea of whether you should be able to run the driver'
  end

  def test_running_basic_tests
    results = run_for_project('basic_project')
    assert_equal 3, results.total_tests, 'Correct number of tests run'
    assert_equal 4, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 0, results.total_failures, 'Correct number of failures given'
  end

  # Make sure we can run tests with DOM operations
  def test_running_dom_tests
    results = run_for_project('dom_project')
    assert_equal 1, results.total_tests, 'Correct number of tests run'
    assert_equal 2, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 0, results.total_failures, 'Correct number of failures given'
  end

  def test_failures_are_recorded_correctly
    results = run_for_project('failures_project')
    assert_equal 4, results.total_tests, 'Correct number of tests run'
    # QUnit calls the log callback (the same it calls for assertions) every time there
    # is a failed expect(num). So add one to this total.
    assert_equal 5 + 1, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 4, results.total_failures, 'Correct number of failures given'
  end

  def test_syntax_error_in_test
    runner = driver_class.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/no_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_syntax_error.js'),
        File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_errors_in_it.js')])

    stderr = capture_stderr { runner.run }
    assert stderr.size > 10, 'Got some stderr output to describe the crash'
    results = runner.results
    assert runner.results.failed?, 'Should fail if syntax error in test'
  end

  protected

  def driver_class
    raise 'Must implement driver_class and return the driver class being tested'
  end

  def run_for_project(project_name)
    runner = runner_for_project(project_name)
    runner.run
  end

  def runner_for_project(project_name)
    Dir.chdir File.join(FIXTURES_DIR, project_name)
    driver_class.new("app/assets/javascripts/*.js", "test/javascripts/*.js")
  end

  def capture_stderr
    previous_stderr, $stderr = $stderr, StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = previous_stderr
  end
end
