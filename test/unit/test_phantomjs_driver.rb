require File.expand_path('../../test_helper', __FILE__)
require 'stringio'

class TestPhantomJsDriver < MiniTest::Unit::TestCase

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

  private

  def run_for_project(project_name)
    runner = runner_for_project(project_name)
    runner.run
    runner.results
  end

  def runner_for_project(project_name)
    Dir.chdir File.join(FIXTURES_DIR, project_name)
    QUnited::Driver::PhantomJs.new("app/assets/javascripts/*.js", "test/javascripts/*.js")
  end

  def capture_stderr
    previous_stderr, $stderr = $stderr, StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = previous_stderr
  end

end
