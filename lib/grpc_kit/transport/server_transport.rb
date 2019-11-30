# frozen_string_literal: true

require 'grpc_kit/transport/packable'

module GrpcKit
  module Transport
    class ServerTransport
      include GrpcKit::Transport::Packable

      # @param session [GrpcKit::ControlQueue]
      # @param stream [GrpcKit::Session::Stream]
      def initialize(control_queue, stream)
        @control_queue = control_queue
        @stream = stream
      end

      # @param headers [Hash<String, String>]
      # @return [void]
      def start_response(headers)
        @control_queue.submit_response(@stream.stream_id, headers)
        send_data
      end

      # @param headers [Hash<String, String>]
      # @return [void]
      def submit_headers(headers)
        @control_queue.submit_headers(@stream.stream_id, headers)
      end

      # @param buf [String]
      # @return [void]
      def write_data(buf)
        @stream.write_send_data(pack(buf))
        send_data
      end

      # @return [nil,String]
      def read_data
        unpack(recv_data)
      end

      # @param trailer [Hash<String, String>]
      # @return [void]
      def write_trailers(trailer)
        @stream.write_trailers_data(trailer)
        send_data
      end

      # @return [Hash<String,String>]
      def recv_headers
        @stream.headers
      end

      private

      def recv_data
        loop do
          data = @stream.read_recv_data
          return data if data

          if @stream.close_remote?
            # Call @stream.read_recv_data after checking @stream.close_remote?
            # because of the order of nghttp2 callbacks which calls a callback receiving data before a callback receiving END_STREAM flag
            data = @stream.read_recv_data
            return data
          end
        end
      end

      def send_data
        @control_queue.resume_data(@stream.stream_id)
      end
    end
  end
end
