# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

require 'logger'

class GreeterServer < Helloworld::Greeter::Service
  def say_hello(hello_req, _unused_call)
    Helloworld::HelloReply.new(message: "Hello #{hello_req.name}")
  end
end

sock = TCPServer.new(50051)

server = GrpcKit::Server.new
server.handle(GreeterServer.new)

trap(:INT) { server.graceful_shutdown(timeout: false) }
trap(:TERM) { server.graceful_shutdown(timeout: false) }
trap(:QUIT) { server.graceful_shutdown(timeout: false) }

logger = Logger.new(STDOUT, level: :debug)
GrpcKit.logger = logger

conn = sock.accept
thread = Thread.new { server.run(conn) }

thread.join
