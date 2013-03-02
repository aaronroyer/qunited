require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../driver_common_tests', __FILE__)

# Test running tests with the PhantomJs driver.
class TestPhantomJsDriver < MiniTest::Unit::TestCase
  include QUnited::DriverCommonTests

  def test_results_are_output_live
    mock_formatter = mock
    mock_formatter.expects(:start)
    mock_formatter.expects(:test_passed).times(3)
    mock_formatter.expects(:stop)
    mock_formatter.expects(:summarize)

    run_tests_for_project 'basic_project', :formatter => mock_formatter
  end

  private

  def driver_class
    ::QUnited::Driver::PhantomJs
  end

end
