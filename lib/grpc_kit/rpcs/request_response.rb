# frozen_string_literal: true

require 'grpc_kit/rpcs/base'
require 'grpc_kit/status_codes'
require 'grpc_kit/calls/server_request_response'
require 'grpc_kit/calls/client_request_response'

module GrpcKit
  module Rpcs
    module Client
      class RequestResponse < Base
        def invoke(stream, request, metadata: {}, timeout: nil)
          call = GrpcKit::Calls::Client::RequestResponse.new(metadata: metadata, config: @config, timeout: timeout, stream: stream)
          @config.interceptor.intercept(request, call, metadata) do |r, c, m|
            if timeout
              Timeout.timeout(timeout.to_f, GrpcKit::Errors::DeadlineExceeded) do
                call.send_msg(r, timeout: timeout.to_s, metadata: c.metadata, last: true)
                call.recv(last: true)
              end
            else
              call.send_msg(r, metadata: c.metadata, last: true)
              call.recv(last: true)
            end
          end
        end
      end
    end

    module Server
      class RequestResponse < Base
        def invoke(stream)
          ss = GrpcKit::Streams::Server.new(stream: stream, config: @config)
          call = GrpcKit::Calls::Server::RequestResponse.new(metadata: stream.headers.metadata, config: @config, stream: ss)

          begin
            do_invoke(ss, call)
          rescue GrpcKit::Errors::BadStatus => e
            GrpcKit.logger.debug(e)
            ss.send_status(status: e.code, msg: e.reason, metadata: {}) # TODO: metadata should be set
          rescue StandardError => e
            GrpcKit.logger.debug(e)
            ss.send_status(status: GrpcKit::StatusCodes::UNKNOWN, msg: e.message, metadata: {})
          end
        end

        private

        def do_invoke(ss, call)
          request = ss.recv_msg(nil, last: true)

          resp =
            if @config.interceptor
              @config.interceptor.intercept(request, call) do |req, c|
                @handler.send(@config.ruby_style_method_name, req, c)
              end
            else
              @handler.send(@config.ruby_style_method_name, request, call)
            end

          ss.send_msg(resp, nil, last: true)
        end
      end
    end
  end
end
