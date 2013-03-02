require File.expand_path('../../test_helper', __FILE__)
require File.expand_path('../driver_common_tests', __FILE__)

# Test running tests with the PhantomJs driver.
class TestPhantomJsDriver < MiniTest::Unit::TestCase
  include QUnited::DriverCommonTests

  private

  def driver_class
    ::QUnited::Driver::PhantomJs
  end

end
