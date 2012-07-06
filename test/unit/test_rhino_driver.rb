require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../driver_common_tests', __FILE__)
require 'stringio'

# Test running tests with the Rhino driver.
class TestRhinoDriver < MiniTest::Unit::TestCase
  include QUnited::DriverCommonTests

  def test_undefined_error_in_source
    runner = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/undefined_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_errors_in_it.js')])

    stderr = capture_stderr { runner.run }
    assert stderr.size > 10, 'Got some stderr output to describe the crash'
    results = runner.results
    assert results.passed?, 'Should succeed even if crash in source file as long as tests pass'
    assert_equal 1, results.total_tests, 'Correct number of tests run'
    assert_equal 1, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 0, results.total_failures, 'Correct number of failures given'
  end

  def test_syntax_error_in_source
    runner = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/syntax_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_errors_in_it.js')])

    stderr = capture_stderr { runner.run }
    assert stderr.size > 10, 'Got some stderr output to describe the crash'
    results = runner.results
    assert runner.results.passed?, 'Should succeed even if crash in source file as long as tests pass'
    assert_equal 1, results.total_tests, 'Correct number of tests run'
    assert_equal 1, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 0, results.total_failures, 'Correct number of failures given'
  end

  def test_undefined_error_in_test
    runner = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/no_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_undefined_error.js')])

    stderr = capture_stderr { runner.run }
    assert stderr.strip.empty?, 'No stderr if test crashes - should have been caught'
    results = runner.results
    assert results.failed?, 'We got a failure with the undefined error'
    assert_equal 2, results.total_tests, 'Correct number of tests run'
    # "assertions" count will actually be 1, plus the unefined error being recorded
    assert_equal 2, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 0, results.total_failures, 'Correct number of failures given'
    # The crashed test errors, but the other should be allowed to succeed
    assert_equal 1, results.total_errors, 'Correct number of errors given'
  end

  def test_no_tests_in_test_file_means_failure
    runner = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/no_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_tests.js')])
    runner.run

    results = runner.results
    assert results.failed?, 'No tests in a file means failure'
  end

  private

  def driver_class
    QUnited::Driver::Rhino
  end

end
