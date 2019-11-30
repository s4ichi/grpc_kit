# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class ServerStreamer < GrpcKit::Call
      include Enumerable

      alias outgoing_metadata metadata

      # @param data [Object] request message
      # @return [void]
      def send_msg(data)
        @stream.send_msg(data, metadata: outgoing_metadata)
      end

      # @return [Object] response object
      def recv
        @stream.recv_msg
      end

      # @yieldparam response [Object] each response object of server streaming RPC
      def each
        loop { yield(recv) }
      end
    end
  end
end
