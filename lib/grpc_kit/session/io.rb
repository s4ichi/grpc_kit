# frozen_string_literal: true

require 'ds9'

module GrpcKit
  module Session
    class IO
      def initialize(io)
        @io = io
      end

      def close
        @io.close
      end

      # @param length [Integer]
      # @return [DS9::ERR_WOULDBLOCK, DS9::ERR_EOF, String]
      def recv_event(length)
        data = @io.read_nonblock(length, nil, exception: false)

        case data
        when :wait_readable
          DS9::ERR_WOULDBLOCK
        when nil # nil means EOF
          DS9::ERR_EOF
        else
          data
        end
      end

      # @param data [String]
      # @return [DS9::ERR_WOULDBLOCK, Integer]
      def send_event(data)
        return 0 if data.empty?

        bytes = @io.write_nonblock(data, exception: false)
        if bytes == :wait_writable
          DS9::ERR_WOULDBLOCK
        else
          bytes
        end
      end

      # Blocking until io object is readable
      # @param timeout [Integer]
      # @return [Boolean] true if readable, otherwise false
      # @raise [IOError] if @io has been closed
      def wait_readable(timeout = nil)
        if ::IO.select([@io], [], [], timeout)
          true
        else
          false
        end
      end

      # Blocking until io object is readable or writable
      # @return [Array<Array<IO>>]
      # @raise [IOError] if @io has been closed
      def select(timeout = 1)
        ::IO.select([@io], [@io], [], timeout)
      end

      # @return [void]
      def flush
        @io.flush
      end
    end
  end
end
