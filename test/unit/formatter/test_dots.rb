require File.expand_path('../../../test_helper', __FILE__)
require 'date'
require 'stringio'

# Test running tests with the Rhino driver.
class TestDots < MiniTest::Unit::TestCase
  def setup
    @output = StringIO.new
    @formatter = ::QUnited::Formatter::Dots.new({:driver_name => 'FakeDriver', :output => @output})
  end

  def test_basic_output
    @formatter.start
    assert_output_equals "\n# Running JavaScript tests with FakeDriver:\n\n"

    @formatter.test_passed create_result([
      create_assertion(:message => 'good assertion 1'),
      create_assertion(:message => 'good assertion 2')
    ])
    assert_output_equals '.'

    @formatter.test_passed create_result([
      create_assertion({ :result => true, :message => "doesn't matter" })
    ])
    assert_output_equals '.'

    @formatter.stop
    @formatter.summarize

    seconds = 0.02

    expected = <<EXPECTED_OUTPUT


Finished in #{'%.6g' % seconds} seconds, #{'%.6g' % (2 / seconds)} tests/s, #{'%.6g' % (3 / seconds)} assertions/s.

2 tests, 3 assertions, 0 failures, 0 errors
EXPECTED_OUTPUT

    assert_output_equals expected
  end

  def test_ok_failure_output
    @formatter.start
    assert_output_equals "\n# Running JavaScript tests with FakeDriver:\n\n"

    msg = "This should be true"
    @formatter.test_failed create_result([
      create_assertion({ :result => false, :message => msg })
    ])
    assert_output_equals 'F'

    @formatter.stop
    @formatter.summarize

    seconds = 0.01

    expected = <<EXPECTED_OUTPUT


Finished in #{'%.6g' % seconds} seconds, #{'%.6g' % (1 / seconds)} tests/s, #{'%.6g' % (1 / seconds)} assertions/s.

  1) Failure:
This stuff should work (My Tests) [something_test.js]
#{msg}

1 tests, 1 assertions, 1 failures, 0 errors
EXPECTED_OUTPUT

    assert_output_equals expected
  end

  def test_equal_failure_output
    @formatter.start
    assert_output_equals "\n# Running JavaScript tests with FakeDriver:\n\n"

    msg = "These strings match"
    expected, actual = "String here", "Other string here"
    @formatter.test_failed create_result([
      create_assertion({ :result => false, :message => msg,
                :expected => expected, :actual => actual })
    ])
    assert_output_equals 'F'

    @formatter.stop
    @formatter.summarize

    seconds = 0.01

    expected = <<EXPECTED_OUTPUT


Finished in #{'%.6g' % seconds} seconds, #{'%.6g' % (1 / seconds)} tests/s, #{'%.6g' % (1 / seconds)} assertions/s.

  1) Failure:
This stuff should work (My Tests) [something_test.js]
#{msg}
Expected: "#{expected}"
  Actual: "#{actual}"

1 tests, 1 assertions, 1 failures, 0 errors
EXPECTED_OUTPUT

    assert_output_equals expected
  end

  def test_equal_with_null_failure_output
    @formatter.start
    assert_output_equals "\n# Running JavaScript tests with FakeDriver:\n\n"

    msg = "These strings match"
    expected, actual = 1, nil
    @formatter.test_failed create_result([
      create_assertion({ :result => false, :message => msg,
                :expected => expected, :actual => actual })
    ])
    assert_output_equals 'F'

    @formatter.stop
    @formatter.summarize

    seconds = 0.01

    expected = <<EXPECTED_OUTPUT


Finished in #{'%.6g' % seconds} seconds, #{'%.6g' % (1 / seconds)} tests/s, #{'%.6g' % (1 / seconds)} assertions/s.

  1) Failure:
This stuff should work (My Tests) [something_test.js]
#{msg}
Expected: 1
  Actual: null

1 tests, 1 assertions, 1 failures, 0 errors
EXPECTED_OUTPUT

    assert_output_equals expected
  end

   def test_failure_output_with_no_file
    @formatter.start
    assert_output_equals "\n# Running JavaScript tests with FakeDriver:\n\n"

    msg = "This should be true"
    @formatter.test_failed create_result([
      create_assertion({ :result => false, :message => msg })
    ], {:file => nil})
    assert_output_equals 'F'

    @formatter.stop
    @formatter.summarize
    
    seconds = 0.01

    expected = <<EXPECTED_OUTPUT


Finished in #{'%.6g' % seconds} seconds, #{'%.6g' % (1 / seconds)} tests/s, #{'%.6g' % (1 / seconds)} assertions/s.

  1) Failure:
This stuff should work (My Tests)
#{msg}

1 tests, 1 assertions, 1 failures, 0 errors
EXPECTED_OUTPUT

    assert_output_equals expected
  end

  def test_multiple_failure_output
    @formatter.start
    assert_output_equals "\n# Running JavaScript tests with FakeDriver:\n\n"

    msg1 = "This should be true"
    @formatter.test_failed create_result([
      create_assertion({ :result => false, :message => msg1 })
    ])
    assert_output_equals 'F'

    msg2 = "These strings match"
    msg3 = "Another thing that should be true"
    expected, actual = "String here", "Other string here"
    @formatter.test_failed create_result([
      create_assertion({ :result => false, :message => msg2,
        :expected => expected, :actual => actual }),
      create_assertion({ :result => false, :message => msg3 })
    ])
    assert_output_equals 'F'

    @formatter.stop
    @formatter.summarize

    seconds = 0.01 * 2

    expected = <<EXPECTED_OUTPUT


Finished in #{'%.6g' % seconds} seconds, #{'%.6g' % (2 / seconds)} tests/s, #{'%.6g' % (3 / seconds)} assertions/s.

  1) Failure:
This stuff should work (My Tests) [something_test.js]
#{msg1}

  2) Failure:
This stuff should work (My Tests) [something_test.js]
#{msg2}
Expected: "#{expected}"
  Actual: "#{actual}"

  3) Failure:
This stuff should work (My Tests) [something_test.js]
#{msg3}

2 tests, 3 assertions, 2 failures, 0 errors
EXPECTED_OUTPUT

    assert_output_equals expected
  end

  private

  def assert_output_equals(string)
    assert_equal string, @output.string
    clear_output
  end

  def clear_output
    @output.truncate(@output.rewind)
  end

  def create_result(assertions=nil, data={})
    assertions ||= [create_assertion]
    QUnited::QUnitTestResult.new({
      :assertion_data => assertions,
      :assertions => assertions.size,
      :duration => 0.010,
      :failed => assertions.select {|a| !a[:result]}.size,
      :file => "something_test.js",
      :module_name => "My Tests",
      :name => "This stuff should work",
      :start => DateTime.now,
      :total => assertions.size
    }.merge(data))
  end

  def create_assertion(data={})
    { :message => 'This is the message', :result => true }.merge(data)
  end
end
