# frozen_string_literal: true

require 'grpc_kit/transport/packable'

module GrpcKit
  module Transport
    class ClientTransport
      include GrpcKit::Transport::Packable

      # @param session [GrpcKit::Session::ClientSession]
      def initialize(session)
        @session = session
        @stream = nil # set later
      end

      # @param data [String]
      # @param headers [Hash<String, String>]
      # @return [void]
      def start_request(data, headers)
        @stream = @session.send_request(headers)
        write_data(data)
      end

      # @return [void]
      def close_and_flush
        send_data # needed?

        @session.start(@stream.stream_id) # needed?
      end

      # @param buf [String]
      # @return [void]
      def write_data(buf)
        write(@stream.pending_send_data, pack(buf))
        send_data
      end

      # @return [nil,String]
      def read_data
        unpack(recv_data)
      end

      # @return [nil,String]
      def read_data_nonblock
        data = nonblock_recv_data
        if data == :wait_readable
          unpack(nil) # nil is needed read buffered data
          :wait_readable
        else
          unpack(data)
        end
      end

      # @return [Hash<String,String>]
      def recv_headers
        wait_close
        @stream.headers
      end

      private

      def wait_close
        # XXX: wait until half close (remote) to get grpc-status
        until @stream.close_remote?
          @session.run_once
        end
      end

      def write(stream, buf)
        stream.write(buf)
      end

      def nonblock_recv_data
        data = @stream.read_recv_data
        return data unless data.nil?

        if @stream.close_remote?
          return nil
        end

        @session.run_once

        :wait_readable
      end

      def recv_data
        loop do
          data = @stream.read_recv_data
          return data unless data.nil?

          if @stream.close_remote?
            # it do not receive data which we need, it may receive invalid grpc-status
            unless @stream.end_read?
              return nil
            end

            return nil
          end

          @session.run_once
        end
      end

      def send_data
        if @stream.pending_send_data.need_resume?
          @session.resume_data(@stream.stream_id)
        end

        @session.run_once
      end
    end
  end
end
