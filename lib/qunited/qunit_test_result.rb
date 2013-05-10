require 'yaml'

module QUnited

  # Contains results data from a QUnit JavaScript test. Useful for passing data
  # to formatters.
  class QUnitTestResult
    class AssertionResult
      attr_accessor :data

      def initialize(assertion_data)
        @data = assertion_data
      end

      def message
        data[:message] || 'Failed assertion, no message given.'
      end

      def result
        if data[:result]
          :passed
        else
          data[:message] =~ /^Died on test/ ? :error : :failed
        end
      end

      def passed?; result == :passed end
      def failed?; result == :failed end
      def error?;  result == :error end

      [:expected, :actual].each do |prop|
        define_method(prop) do
          data[prop]
        end
      end
    end

    def self.from_json(json)
      self.new clean_up_result(::YAML.load(json))
    end

    attr_accessor :data

    def initialize(test_data)
      @data = test_data
    end

    def passed?; result == :passed end
    def failed?; result == :failed end
    def error?;  result == :error end

    def result
      @result ||= if assertions.find { |a| a.error? }
        :error
      else
        assertions.find { |a| a.failed? } ? :failed : :passed
      end
    end

    def assertions
      @assertions ||= data[:assertion_data].map { |assertion_data| AssertionResult.new assertion_data }
    end

    [:name, :module_name, :duration, :file].each do |prop|
      define_method(prop) do
        data[prop]
      end
    end

    private

    # Turn String keys into Symbols and convert Strings representing dates
    # and numbers into their appropriate objects.
    def self.clean_up_result(test_result)
      test_result = symbolize_keys(test_result)
      test_result[:start] = DateTime.parse(test_result[:start])
      test_result
    end

    def self.symbolize_keys(obj)
      case obj
      when Hash
        obj.inject({}) do |new_hash, (key, value)|
          new_hash[key.to_sym] = symbolize_keys(value)
          new_hash
        end
      when Array
        obj.map { |x| symbolize_keys(x) }
      else
        obj
      end
    end
  end
end
