module QUnited
  module Driver

    # Collects test results from lines of JavaScript interpreter output.
    #
    # QUnited test running drivers may run a JavaScript interpreter in a separate process and
    # observe the output (say, on stdout) for text containing test results. These results may
    # be delimited by tokens that allow ResultsCollector to recognize the beginning and end of
    # JSON test results. The test running driver must be properly configured to emit the correct
    # tokens, matching TEST_RESULT_START_TOKEN and TEST_RESULT_END_TOKEN before and after strings
    # of test results serialized as valid JSON.
    #
    # If everything is set up correctly the recognized results are parsed and QUnitTestResult
    # objects are produced for each.
    #
    #
    # To use, initialize with the IO object that provides the output from the test running
    # process. Then call on_test_result with a block to be called when a test is collected.
    # A QUnited::QUnitTestResult object will be passed to the block for each test.
    #
    #   rc = ResultsCollector.new(stdout_from_test_runner)
    #   rc.on_test_result {|test_result| puts "I've got a result: #{test_result.inspect}" }
    #
    # If you need to capture output that is not part of any test result, you can call
    # on_non_test_result_line with another block to do this. Each line of output that is not part
    # of test result JSON is passed to the block.
    #
    #   rc.on_non_test_result_line {|line| puts "This line is not part of a test result: #{line}"}
    #
    class ResultsCollector
      TEST_RESULT_START_TOKEN = 'QUNITED_TEST_RESULT_START_TOKEN'
      TEST_RESULT_END_TOKEN   = 'QUNITED_TEST_RESULT_END_TOKEN'
      TEST_RESULT_REGEX       = /#{TEST_RESULT_START_TOKEN}(.*?)#{TEST_RESULT_END_TOKEN}/m

      def initialize(io)
        @io = io
        @results = []
        @on_test_result_block = nil
        @on_non_test_result_line_block = nil
        @partial_test_result = ''
      end

      # Set a block to be called when a test result has been parsed. The block is passed a
      # QUnitTestResult object.
      def on_test_result(&block)
        raise ArgumentError.new('must provide a block') unless block_given?
        @on_test_result_block = block
      end

      # Set a block to be called when a line of output is read from the IO object that is not
      # part of a test result. The block is passed the line of output.
      def on_non_test_result_line(&block)
        raise ArgumentError.new('must provide a block') unless block_given?
        @on_non_test_result_line_block = block
      end

      # Read all available lines from the IO and parse results from it. If blocks have been set
      # with on_test_result and/or on_non_test_result_line they will be called when appropriate.
      def collect_results
        while collect_next_line; end
      end

      # Read the next line from the IO and parse results from it, if applicable. If blocks have
      # been set with on_test_result and/or on_non_test_result_line they will be called when
      # appropriate.
      #
      # Usually collect_results should be used unless lines need to be read one at a time for
      # some reason.
      def collect_next_line
        line = @io.gets
        return nil unless line

        if line =~ ::QUnited::Driver::Base::TEST_RESULT_REGEX
          process_test_result $1

        elsif line.include?(::QUnited::Driver::Base::TEST_RESULT_START_TOKEN)
          @partial_test_result << line.sub(::QUnited::Driver::Base::TEST_RESULT_START_TOKEN, '')

        elsif line.include?(::QUnited::Driver::Base::TEST_RESULT_END_TOKEN)
          @partial_test_result << line.sub(::QUnited::Driver::Base::TEST_RESULT_END_TOKEN, '')
          process_test_result @partial_test_result
          @partial_test_result = ''

        elsif !@partial_test_result.empty?
          # Middle of a test result
          @partial_test_result << line

        else
          @on_non_test_result_line_block.call(line) if @on_non_test_result_line_block

        end

        line
      end

      private

      def process_test_result(test_result_json)
        result = ::QUnited::QUnitTestResult.from_json(test_result_json)
        @results << result
        @on_test_result_block.call(result) if @on_test_result_block
      end
    end
  end
end
