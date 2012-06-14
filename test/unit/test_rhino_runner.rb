require File.expand_path('../../test_helper', __FILE__)

class TestRhinoRunner < MiniTest::Unit::TestCase

  def test_running_basic_tests
    Dir.chdir File.join(FIXTURES_DIR, 'basic_project')
    runner = QUnited::Runner::Rhino.new("app/assets/javascripts/*.js", "test/javascripts/*.js")
    results = runner.run.results
    assert_equal 3, results.total_tests, 'Correct number of tests run'
    assert_equal 4, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 0, results.total_failures, 'Correct number of failures given'
  end

  # Make sure we can run tests with DOM operations
  def test_running_dom_tests
    Dir.chdir File.join(FIXTURES_DIR, 'dom_project')
    runner = QUnited::Runner::Rhino.new("app/assets/javascripts/*.js", "test/javascripts/*.js")
    results = runner.run.results
    assert_equal 1, results.total_tests, 'Correct number of tests run'
    assert_equal 2, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 0, results.total_failures, 'Correct number of failures given'
  end

  def test_failures_are_recorded_correctly
    Dir.chdir File.join(FIXTURES_DIR, 'failures_project')
    runner = QUnited::Runner::Rhino.new("app/assets/javascripts/*.js", "test/javascripts/*.js")
    results = runner.run.results
    assert_equal 4, results.total_tests, 'Correct number of tests run'
    # QUnit calls the log callback (the same it calls for assertions) every time there
    # is a failed expect(num). So add one.
    assert_equal 5 + 1, results.total_assertions, 'Correct number of assertions executed'
    assert_equal 4, results.total_failures, 'Correct number of failures given'
  end
end
