require File.expand_path('../../test_helper', __FILE__)

class AvailableDriver
  def self.available?; true end
end

class NotAvailableDriver
  def self.available?; false end
end

class TestRunner < MiniTest::Unit::TestCase
  def test_raises_exception_with_nonexistent_driver
    runner = QUnited::Runner.new(['source.js'], ['test.js'], { driver: :doesNotExist })
    assert_raises(QUnited::UsageError) do
      runner.resolve_driver_class
    end
  end

  def test_specified_driver_can_be_used_if_available
    runner = QUnited::Runner.new(['source.js'], ['test.js'], { driver: :AvailableDriver })

    def runner.get_driver(klass)
      if klass == :AvailableDriver
        AvailableDriver
      else
        raise 'Only :AvailableDriver is used for this test'
      end
    end
    runner.resolve_driver_class # Nothing raised
  end

  def test_raises_exception_when_not_available_driver_is_specified
    runner = QUnited::Runner.new(['source.js'], ['test.js'], { driver: :NotAvailableDriver })

    def runner.get_driver(klass)
      if klass == :NotAvailableDriver
        NotAvailableDriver
      else
        raise 'Only :NotAvailableDriver is used for this test'
      end
    end

    assert_raises(QUnited::UsageError) do
      runner.resolve_driver_class
    end
  end

  def test_raises_exception_when_no_driver_specified_and_no_drivers_available
    runner = QUnited::Runner.new(['source.js'], ['test.js'])

    # Make every driver the NotAvailable driver
    def runner.get_driver(klass)
      NotAvailableDriver
    end

    assert_raises(QUnited::UsageError) do
      runner.resolve_driver_class
    end
  end
end
