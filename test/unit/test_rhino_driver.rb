require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../driver_common_tests', __FILE__)

# Test running tests with the Rhino driver.
class TestRhinoDriver < MiniTest::Unit::TestCase
  include QUnited::DriverCommonTests

  def test_undefined_error_in_source
    driver = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/undefined_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_errors_in_it.js')])

    driver.run
    assert captured_stderr.size > 10, 'Got some stderr output to describe the crash'
    @results = driver.results
    assert @results.all? { |r| r.passed? }, 'Should succeed even if crash in source file as long as tests pass'
    assert_equal 1, total_tests, 'Correct number of tests run'
    assert_equal 1, total_assertions, 'Correct number of assertions executed'
    assert_equal 0, total_failed_tests, 'Correct number of test failures given'
    assert_equal 0, total_failed_assertions, 'Correct number of assertion failures given'
  end

  def test_syntax_error_in_source
    driver = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/syntax_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_errors_in_it.js')])

    driver.run
    assert captured_stderr.size > 10, 'Got some stderr output to describe the crash'
    @results = driver.results
    assert @results.all? { |r| r.passed? }, 'Should succeed even if crash in source file as long as tests pass'
    assert_equal 1, total_tests, 'Correct number of tests run'
    assert_equal 1, total_assertions, 'Correct number of assertions executed'
    assert_equal 0, total_failed_tests, 'Correct number of failures given'
    assert_equal 0, total_failed_assertions, 'Correct number of assertion failures given'
  end

  def test_undefined_error_in_test
    driver = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/no_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_undefined_error.js')])

    driver.run
    assert captured_stderr.strip.empty?, 'No stderr if test crashes - should have been caught'
    @results = driver.results
    assert_equal 2, total_tests, 'Correct number of tests run'
    # "assertions" count will actually be 1, plus the undefined error being recorded
    assert_equal 2, total_assertions, 'Correct number of assertions executed'
    assert_equal 0, total_failed_tests, 'Correct number of failures given'
    # The crashed test errors, but the other should be allowed to succeed
    assert_equal 1, total_error_tests, 'Correct number of errors given'
  end

  def test_no_tests_in_test_file_means_failure
    driver = QUnited::Driver::Rhino.new(
      [File.join(FIXTURES_DIR, 'errors_project/app/assets/javascripts/no_error.js')],
      [File.join(FIXTURES_DIR, 'errors_project/test/javascripts/this_test_has_no_tests.js')])
    driver.run

    @results = driver.results
    assert @results.find { |r| r.failed? }, 'No tests in a file means failure'
  end

  private

  def driver_class
    QUnited::Driver::Rhino
  end

end
