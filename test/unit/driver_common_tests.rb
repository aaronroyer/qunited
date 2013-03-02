require 'stringio'

# Common driver tests that should pass for any implementation of
# QUnited::Driver::Base. There are also a few utility methods included.
module QUnited::DriverCommonTests
  def setup
    start_capture_streams
  end

  def teardown
    stop_capture_streams
  end

  def test_driver_available
    assert driver_class.available?, 'Driver should be available - if it is not then ' +
      'either the available? method has a bug or you do not have the proper environment ' +
      "to run the driver; check the available? method in the #{driver_class} driver class " +
      'to get an idea of whether you should be able to run the driver'
  end

  def test_running_basic_tests
    @results = run_tests_for_project('basic_project')
    assert_equal 3, total_tests, 'Correct number of tests run'
    assert_equal 4, total_assertions, 'Correct number of assertions executed'
    assert_equal 0, total_failed_tests, 'Correct number of failures given'
  end

  # Make sure we can run tests with DOM operations
  def test_running_dom_tests
    @results = run_tests_for_project('dom_project')
    assert_equal 1, total_tests, 'Correct number of tests run'
    assert_equal 2, total_assertions, 'Correct number of assertions executed'
    assert_equal 0, total_failed_tests, 'Correct number of failures given'
  end

  def test_failures_are_recorded_correctly
    @results = run_tests_for_project('failures_project')
    assert_equal 4, total_tests, 'Correct number of tests run'
    # QUnit calls the log callback (the same it calls for assertions) every time there
    # is a failed expect(num). So add one to this total.
    assert_equal 5 + 1, total_assertions, 'Correct number of assertions executed'
    assert_equal 3, total_failed_tests, 'Correct number of failed tests given'
    assert_equal 4, total_failed_assertions, 'Correct number of failed assertions given'
  end

  def test_syntax_error_in_test
    driver = driver_class.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/no_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_syntax_error.js'),
        File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_errors_in_it.js')])

    driver.run
    stderr = captured_stderr
    assert stderr.size > 10, 'Got some stderr output to describe the crash'
    @results = driver.results
    assert total_failed_tests.size > 0, 'Should fail if syntax error in test'
  end

  def test_proper_formatter_methods_are_called_when_tests_pass
    mock_formatter = mock
    mock_formatter.expects(:start)
    mock_formatter.expects(:test_passed).times(3)
    mock_formatter.expects(:stop)
    mock_formatter.expects(:summarize)

    run_tests_for_project 'basic_project', :formatter => mock_formatter
  end

  protected

  def driver_class
    raise 'Must implement driver_class and return the driver class being tested'
  end

  def run_tests_for_project(project_name, driver_opts={})
    driver = driver_for_project(project_name, driver_opts)
    driver.run
  end

  def driver_for_project(project_name, opts={})
    Dir.chdir File.join(FIXTURES_DIR, project_name)
    driver = driver_class.new("app/assets/javascripts/*.js", "test/javascripts/*.js")
    driver.formatter = opts[:formatter] if opts[:formatter]
    driver
  end

  def start_capture_streams
    @original_stdout, $stdout = $stdout, StringIO.new
    @original_stderr, $stderr = $stderr, StringIO.new
  end

  def stop_capture_streams
    $stdout, $stderr = @original_stdout, @original_stderr
  end

  def captured_stdout
    $stdout.string
  end

  def captured_stderr
    $stderr.string
  end


  def total_tests
    @results.size
  end

  def total_failed_tests
    @results.select { |tr| tr.failed? }.size
  end

  def total_error_tests
    @results.select { |tr| tr.error? }.size
  end

  def total_assertions
    @results.inject(0) { |total, result| total += result.assertions.size}
  end

  def total_failed_assertions
    @results.inject(0) { |total, result| total += result.assertions.select { |a| a.failed? }.size }
  end
end
