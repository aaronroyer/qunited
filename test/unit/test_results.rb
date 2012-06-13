require File.expand_path('../../test_helper', __FILE__)

class TestResults < MiniTest::Unit::TestCase
  def test_gives_you_various_counts
    results = QUnited::Results.new test_module_results
    assert_equal 3, results.total_tests, 'Gives total tests count'
    assert_equal 4, results.total_assertions, 'Gives total assertions count'
    assert_equal 0, results.total_failures, 'Gives total failures count when there are none'

    other_results = QUnited::Results.new test_failed_module_results
    assert_equal 2, other_results.total_tests, 'Gives total tests count'
    assert_equal 10, other_results.total_assertions, 'Gives total assertions count'
    assert_equal 2, other_results.total_failures, 'Gives total failures count when there are some'
  end

  private

  def test_module_results
    [
      { :name => "(no module)",
        :tests => [
          { :name => "The source code was loaded",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 1,
            :duration => 0.002,
            :failed => 0,
            :total => 1
          }
        ]
      },
      { :name => "Math",
        :tests =>[
          { :name => "Addition works",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 2,
            :duration => 0.01,
            :failed => 0,
            :total => 2
          },
          { :name => "Subtraction works",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 1,
            :duration => 0.009,
            :failed => 0,
            :total => 1
          }
        ]
      }
    ]
  end

  def test_failed_module_results
    [
      { :name => "Apples",
        :tests => [
          { :name => "Slicing is nice",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 3,
            :duration => 0.022,
            :failed => 2,
            :total => 3
          }
        ]
      },
      { :name => "Oranges",
        :tests =>[
          { :name => "Peeling is hard",
            :failures => [],
            :start => DateTime.parse('2012-06-12T23:52:33+00:00'),
            :assertions => 7,
            :duration => 0.009,
            :failed => 0,
            :total => 7
          }
        ]
      }
    ]
  end
end
