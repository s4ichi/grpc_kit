# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('./examples/helloworld')

require 'grpc_kit'
require 'socket'
require 'pry'
require 'helloworld_services_pb'

HOST = 'localhost'
PORT = 50051

sock = TCPSocket.new(HOST, PORT)
stub = Helloworld::Greeter::Stub.new(sock)

logger = Logger.new(STDOUT, level: :debug)
GrpcKit.logger = logger

loop do
  message = stub.say_hello(Helloworld::HelloRequest.new(name: 'ganmacs')).message
  puts message
  sleep(2)
end
