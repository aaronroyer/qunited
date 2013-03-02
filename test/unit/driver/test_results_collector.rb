require File.expand_path('../../../test_helper', __FILE__)
require 'stringio'

class TestResultsCollector < MiniTest::Unit::TestCase
  def setup
    @io = StringIO.new
    @results_collector = QUnited::Driver::ResultsCollector.new(@io)
  end

  def test_must_be_initialized_with_io_object
    assert_raises(ArgumentError) { QUnited::Driver::ResultsCollector.new }
    QUnited::Driver::ResultsCollector.new(@io)
  end

  def test_on_test_result_must_be_given_a_block
    assert_raises(ArgumentError) { @results_collector.on_test_result }
    @results_collector.on_test_result { |result| }
  end

  def test_on_test_result_block_is_called_when_test_results_are_parsed
    collected_results = []
    @results_collector.on_test_result { |result| collected_results << result }

    @io.puts two_tests_output
    @io.rewind

    @results_collector.collect_results

    assert_equal 2, collected_results.size, 'The correct number of results have been collected'
    assert collected_results.all? {|result| result.is_a? QUnited::QUnitTestResult }, 'Test results are the correct type'
  end

  def test_results_can_be_collected_with_other_lines_mixed_in
    collected_results = []
    @results_collector.on_test_result { |result| collected_results << result }

    @io.puts two_tests_output_with_other_lines_mixed_in
    @io.rewind

    @results_collector.collect_results

    assert_equal 2, collected_results.size, 'The correct number of results have been collected'
    assert collected_results.all? {|result| result.is_a? QUnited::QUnitTestResult }, 'Test results are the correct type'
  end

  def test_one_line_test_results_are_ok
    output = QUnited::Driver::ResultsCollector::TEST_RESULT_START_TOKEN +
      %|{ "assertion_data": [{ "actual": 1, "expected": 1, "message": "This is fine", "result": true }], | +
      %|"assertions": 1, "duration": 0.001, "failed": 0, "file": "", "module_name": "(no module)", | +
      %|"name": "Just a test", "start": "2013-03-02T21:52:30.000Z", "total": 1 }}| +
      QUnited::Driver::ResultsCollector::TEST_RESULT_END_TOKEN

    collected_results = []
    @results_collector.on_test_result { |result| collected_results << result }

    @io.puts output
    @io.rewind

    @results_collector.collect_results

    assert_equal 1, collected_results.size, 'The correct number of results have been collected'
    assert collected_results.all? {|result| result.is_a? QUnited::QUnitTestResult }, 'Test results are the correct type'
  end

  def test_on_non_test_result_line_must_be_given_a_block
    assert_raises(ArgumentError) { @results_collector.on_non_test_result_line }
    @results_collector.on_non_test_result_line { |line| }
  end

  def test_non_test_result_lines_can_be_captured
    stray_lines = []
    @results_collector.on_non_test_result_line { |line| stray_lines << line }

    @io.puts two_tests_output_with_other_lines_mixed_in
    @io.rewind

    @results_collector.collect_results

    assert_equal 4, stray_lines.size, 'The correct number of non test result lines have been collected'
    assert stray_lines.all? {|line| line.is_a? String }, 'Other lines are all strings'
    assert_equal "This is some other output\n", stray_lines[0], 'Line content is correct'
    assert_equal "This is another with a blank line after it\n", stray_lines[1], 'Line content is correct'
    assert_equal "\n", stray_lines[2], 'Can even get blank lines'
    assert_equal "And another line at the end\n", stray_lines[3], 'Line content is correct'
  end

  private

  def two_tests_output
    output = <<RAW_OUTPUT
#{QUnited::Driver::ResultsCollector::TEST_RESULT_START_TOKEN}
{
 "assertion_data": [
  {
   "actual": 1,
   "expected": 1,
   "message": "This is fine",
   "result": true
  }
 ],
 "assertions": 1,
 "duration": 0.001,
 "failed": 0,
 "file": "",
 "module_name": "(no module)",
 "name": "Just a test",
 "start": "2013-03-02T21:52:30.000Z",
 "total": 1
}
#{QUnited::Driver::ResultsCollector::TEST_RESULT_END_TOKEN}
#{QUnited::Driver::ResultsCollector::TEST_RESULT_START_TOKEN}
{
 "assertion_data": [
  {
   "actual": 1,
   "expected": 1,
   "message": "This is also fine",
   "result": true
  }
 ],
 "assertions": 1,
 "duration": 0.003,
 "failed": 0,
 "file": "",
 "module_name": "(no module)",
 "name": "Just another test",
 "start": "2013-03-02T21:52:33.000Z",
 "total": 1
}
#{QUnited::Driver::ResultsCollector::TEST_RESULT_END_TOKEN}
RAW_OUTPUT

  output
  end

  def two_tests_output_with_other_lines_mixed_in
    output = <<RAW_OUTPUT
This is some other output
#{QUnited::Driver::ResultsCollector::TEST_RESULT_START_TOKEN}
{
 "assertion_data": [
  {
   "actual": 1,
   "expected": 1,
   "message": "This is fine",
   "result": true
  }
 ],
 "assertions": 1,
 "duration": 0.001,
 "failed": 0,
 "file": "",
 "module_name": "(no module)",
 "name": "Just a test",
 "start": "2013-03-02T21:52:30.000Z",
 "total": 1
}
#{QUnited::Driver::ResultsCollector::TEST_RESULT_END_TOKEN}
This is another with a blank line after it

#{QUnited::Driver::ResultsCollector::TEST_RESULT_START_TOKEN}
{
 "assertion_data": [
  {
   "actual": 1,
   "expected": 1,
   "message": "This is also fine",
   "result": true
  }
 ],
 "assertions": 1,
 "duration": 0.003,
 "failed": 0,
 "file": "",
 "module_name": "(no module)",
 "name": "Just another test",
 "start": "2013-03-02T21:52:33.000Z",
 "total": 1
}
#{QUnited::Driver::ResultsCollector::TEST_RESULT_END_TOKEN}
And another line at the end
RAW_OUTPUT

  output
  end
end
