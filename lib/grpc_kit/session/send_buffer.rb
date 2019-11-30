# frozen_string_literal: true

module GrpcKit
  module Session
    class SendBuffer
      def initialize
        @buffer = ''.b
        @end_write = false
        @deferred_read = false
        @mutex = Mutex.new
      end

      # @param data [String]
      # @return [void]
      def write(data)
        @mutex.synchronize { @buffer << data }
      end

      # @return [Boolean]
      def need_resume?
        @deferred_read
      end

      def no_resume
        @deferred_read = false
      end

      def empty?
        @mutex.synchronize { @buffer.empty? }
      end

      # @param size [Integer,nil]
      # @return [nil,DS9::ERR_DEFERRED,String]
      def read(size = nil)
        buf = do_read(size)
        if buf
          @deferred_read = false
          return buf
        end

        @deferred_read = true
        DS9::ERR_DEFERRED
      end

      private

      def do_read(size = nil)
        @mutex.synchronize do
          if @buffer.empty?
            nil
          elsif size.nil? || @buffer.bytesize < size
            buf = @buffer
            @buffer = ''.b
            buf
          else
            @buffer.freeze
            rbuf = @buffer.byteslice(0, size)
            @buffer = @buffer.byteslice(size, @buffer.bytesize)
            rbuf
          end
        end
      end
    end
  end
end
