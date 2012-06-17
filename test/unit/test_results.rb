require File.expand_path('../../test_helper', __FILE__)

class TestResults < MiniTest::Unit::TestCase

  def test_gives_you_various_counts
    results = QUnited::Results.new test_module_results
    assert results.passed?, 'passed? is true when all tests have passed'
    assert !results.failed?, 'failed? is false when all tests have passed'
    assert_equal 3, results.total_tests, 'total_tests gives total tests count'
    assert_equal 4, results.total_assertions, 'total_assertions gives total assertions count'
    assert_equal 0, results.total_failures, 'total_failures gives total failures count when there are none'
    assert_equal 0, results.total_errors, 'total_errors gives total errors when there are none'

    other_results = QUnited::Results.new test_failed_module_results

    assert !other_results.passed?, 'passed? is false when there are failures'
    assert other_results.failed?, 'failed? is true when there are failures'
    assert_equal 4, other_results.total_tests, 'total_tests gives total tests count'
    assert_equal 5 + 1, other_results.total_assertions, 'total_assertions gives total assertions count'
    assert_equal 4, other_results.total_failures, 'total_failures gives total failures count when there are some'
    assert_equal 0, results.total_errors, 'total_errors gives total errors when there are none'
  end

  def test_basic_output
    results = QUnited::Results.new test_module_results
    assert_equal "3 tests, 4 assertions, 0 failures, 0 errors, 0 skips", results.bottom_line
    assert_equal "...", results.dots
  end

  def test_failures_output
    results = QUnited::Results.new test_failed_module_results

    assert_equal "4 tests, 6 assertions, 4 failures, 0 errors, 0 skips", results.bottom_line
    assert_equal "F.FF", results.dots

    failure = results.failures_output_array[0].split("\n")
    assert_equal 3, failure.size
    assert_equal '  1) Failure:', failure[0]
    assert_equal 'This has one failure (Basics) [test/javascripts/test_basics.js]', failure[1]
    assert_equal 'Failed assertion, no message given.', failure[2]

    failure = results.failures_output_array[1].split("\n")
    assert_equal 5, failure.size
    assert_equal '  2) Failure:', failure[0]
    assert_equal 'Addition is hard (Math) [test/javascripts/test_math.js]', failure[1]
    assert_equal 'I got my math right', failure[2]
    assert_equal 'Expected: 3', failure[3]
    assert_equal '  Actual: 2', failure[4]

    failure = results.failures_output_array[2].split("\n")
    assert_equal 5, failure.size
    assert_equal '  3) Failure:', failure[0]
    assert_equal 'Addition is hard (Math) [test/javascripts/test_math.js]', failure[1]
    assert_equal 'These strings match', failure[2]
    assert_equal 'Expected: "String here"', failure[3]
    assert_equal '  Actual: "Identical string here"', failure[4]

    failure = results.failures_output_array[3].split("\n")
    assert_equal 3, failure.size
    assert_equal '  4) Failure:', failure[0]
    assert_equal 'Check some subtraction (Math) [test/javascripts/test_math.js]', failure[1]
    assert_equal 'Expected 2 assertions, but 1 were run', failure[2]
  end

  # Test results are converted to JavaScript appropriate null, not nil
  def test_null_failures_output
    results = QUnited::Results.new test_failed_module_results_with_null

    failure = results.failures_output_array[0].split("\n")
    assert_equal 5, failure.size
    assert_equal '  1) Failure:', failure[0]
    assert_equal 'The test (The module) [test/javascripts/test_module.js]', failure[1]
    assert_equal 'Was it null?', failure[2]
    assert_equal 'Expected: 5', failure[3]
    assert_equal '  Actual: null', failure[4]
  end

  def test_errors_and_error_output
    results = QUnited::Results.new test_failed_module_results_with_an_error

    assert results.failed?, 'failed? is true when there are errors'
    assert_equal 2, results.total_tests, 'total_tests gives total tests count'
    assert_equal 3, results.total_assertions, 'total_assertions gives total assertions count'
    assert_equal 0, results.total_failures, 'total_failures gives total failures count when there are none'
    assert_equal 1, results.total_errors, 'total_errors gives total errors when there are none'

    error = results.failures_output_array[0].split("\n")
    assert_equal 3, error.size
    assert_equal '  1) Error:', error[0]
    assert_equal 'Error test (The module) [test/javascripts/test_module.js]', error[1]
    assert_equal 'Died on test #3: asdf is undefined', error[2]

    assert_equal "2 tests, 3 assertions, 0 failures, 1 errors, 0 skips", results.bottom_line
    assert_equal "E.", results.dots
  end

  private

  def test_module_results
    [
      {
        :name => "(no module)",
        :tests => [
          { :name => "The source code was loaded",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 1,
            :duration => 0.002,
            :failed => 0,
            :total => 1,
            :file => 'test/javascripts/test_basics.js',
            :assertion_data => [
              { :result => true,
                :message => "We have loaded it",
                :actual => 1,
                :expected => 1
              }
            ]
          }
        ]
      },
      { :name => "Math",
        :tests =>[
          {
            :name => "Addition works",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 2,
            :duration => 0.01,
            :failed => 0,
            :total => 2,
            :file => 'test/javascripts/test_math.js',
            :assertion_data => [
              {
                :result => true,
                :message => "One plus one does equal two",
                :actual => 2,
                :expected => 2
              },
              {
                :result => true,
                :message => "Two plus two does equal four",
                :actual => 4,
                :expected => 4
              }
            ]
          },
          { :name => "Subtraction works",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 1,
            :duration => 0.009,
            :failed => 0,
            :total => 1,
            :file => 'test/javascripts/test_math.js',
            :assertion_data => [
              {
                :result=>true,
                :message=>"Two minus one equals one",
                :actual=>1,
                :expected=>1
              }
            ]
          }
        ]
      }
    ]
  end

  def test_failed_module_results
    [
      {
        :name => "Basics",
        :tests =>  [
          {
            :name => "This has one failure",
            :assertion_data => [
              {
                :result => false,
                :message => nil
              }
            ],
            :start => DateTime.parse('2012-06-14T13:24:11+00:00'),
            :assertions => 1,
            :file => "test/javascripts/test_basics.js",
            :duration => 0.002,
            :failed => 1,
            :total => 1
          },
          {
            :name => "This has no failures",
            :assertion_data => [
              {
                :result => true,
                :message => "It is 1",
                :actual => 1,
                :expected => 1
              }
            ],
            :start => DateTime.parse('2012-06-14T13:24:11+00:00'),
            :assertions => 1,
            :file => "test/javascripts/test_basics.js",
            :duration => 0.006,
            :failed => 0,
            :total => 1
          }
        ]
      },
      {
        :name => "Math",
        :tests => [
          {
            :name => "Addition is hard",
            :assertion_data => [
              {
                :result => false,
                :message => "I got my math right",
                :actual => 2,
                :expected => 3
              },
              {
                :result => false,
                :message => "These strings match",
                :actual => "Identical string here",
                :expected => "String here"
              }
            ],
            :start => DateTime.parse('2012-06-14T13:24:11+00:00'),
            :assertions => 2,
            :file => "test/javascripts/test_math.js",
            :duration => 0.02,
            :failed => 2,
            :total => 2
          },
          {
            :name => "Check some subtraction",
            :assertion_data => [
              {
                :result => true,
                :message => "Two minus one equals one",
                :actual => 1,
                :expected => 1
              },
              {
                :result => false,
                :message => "Expected 2 assertions, but 1 were run"
              }
            ],
            :start => DateTime.parse('2012-06-14T13:24:11+00:00'),
            :assertions => 2,
            :file => "test/javascripts/test_math.js",
            :duration => 0.008,
            :failed => 1,
            :total => 2
          }
        ]
      }
    ]
  end

  def test_failed_module_results_with_null
    [
      {
        :name => "The module",
        :tests =>  [
          {
            :name => "The test",
            :assertion_data => [
              {
                :result => false,
                :message => "Was it null?",
                :actual => nil,
                :expected => 5
              }
            ],
            :start => DateTime.parse('2012-06-14T13:24:11+00:00'),
            :assertions => 1,
            :file => "test/javascripts/test_module.js",
            :duration => 0.002,
            :failed => 1,
            :total => 1
          }
        ]
      }
    ]
  end

  def test_failed_module_results_with_an_error
    [
      {
        :name => "The module",
        :tests =>  [
          {
            :name => "Error test",
            :assertion_data => [
              {
                :result => true,
                :message => "This one fine",
                :actual => "String",
                :expected => "String"
              },
              {
                :result => false,
                :message => "Died on test #3: asdf is undefined"
              }

            ],
            :start => DateTime.parse('2012-06-14T13:24:11+00:00'),
            :assertions => 2,
            :file => "test/javascripts/test_module.js",
            :duration => 0.002,
            :failed => 1,
            :total => 2
          },
          {
            :name => "OK test",
            :assertion_data => [
              {
                :result => true,
                :message => "All good",
                :actual => 5,
                :expected => 5
              }

            ],
            :start => DateTime.parse('2012-06-14T13:24:11+00:00'),
            :assertions => 1,
            :file => "test/javascripts/test_module.js",
            :duration => 0.002,
            :failed => 0,
            :total => 1
          }
        ]
      }
    ]
  end

end
