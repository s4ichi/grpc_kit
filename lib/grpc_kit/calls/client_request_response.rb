# frozen_string_literal: true

require 'grpc_kit/call'
require 'grpc_kit/calls'

module GrpcKit
  module Calls::Client
    class RequestResponse < GrpcKit::Call
      alias outgoing_metadata metadata

      # @param data [Object] request message
      # @param last [Boolean]
      # @return [void]
      def send_msg(data, last: false)
        @stream.send_msg(data, last: last, metadata: outgoing_metadata)
      end

      # @param last [Boolean]
      # @return [Object] response object
      def recv(last: false)
        @stream.recv_msg(last: last)
      end
    end
  end
end
