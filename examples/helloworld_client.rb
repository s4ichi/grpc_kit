# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

require 'logger'

HOST = 'localhost'
PORT = 50051

# 8bytes * size
# 8 * 8192 bytes = 65536 bytes over -> failed
MESSAGE = "12345678" * 8192
puts "request message bytesize: #{MESSAGE.bytesize} bytes"

logger = Logger.new(STDOUT, level: :debug)
GrpcKit.logger = logger

settings = [
  [DS9::Settings::MAX_FRAME_SIZE, 70000],
]

ds9_option = DS9::Option.new.tap do |o|
  # o.set_no_auto_window_update
end

sock = TCPSocket.new(HOST, PORT)
stub = Helloworld::Greeter::Stub.new(sock, http2_settings: settings, ds9_option: ds9_option)

message = stub.say_hello(Helloworld::HelloRequest.new(name: MESSAGE)).message

puts 'Received!' if message
