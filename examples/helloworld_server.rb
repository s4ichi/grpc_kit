# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

require 'logger'


# 8bytes * size
# 8 * 8192 bytes = 65536 bytes over -> failed
MESSAGE = "12345678" * 8192
puts "response message bytesize: #{MESSAGE.bytesize} bytes"

class GreeterServer < Helloworld::Greeter::Service
  def say_hello(hello_req, _unused_call)
    Helloworld::HelloReply.new(
      message: MESSAGE
    )
  end
end

settings = [
  [DS9::Settings::MAX_FRAME_SIZE, 70000],
]

logger = Logger.new(STDOUT, level: :debug)
GrpcKit.logger = logger

sock = TCPServer.new(50051)

server = GrpcKit::Server.new(settings: settings)
server.handle(GreeterServer.new)

loop do
  conn = sock.accept
  server.run(conn)
end
