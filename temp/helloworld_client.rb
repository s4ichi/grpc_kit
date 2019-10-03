# frozen_string_literal: true

this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, '.')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'pry'

require 'grpc'
require 'helloworld_services_pb.rb'

require 'logging'
require 'logger'

host = ENV['HOST'] || '0.0.0.0'
port = ENV['PORT'] || '50051'

module GRPC
  extend Logging.globally
end

Logging.logger.root.appenders = Logging.appenders.stdout
Logging.logger.root.level = :debug
Logging.logger['GRPC'].level = :debug
Logging.logger['GRPC::ActiveCall'].level = :debug
Logging.logger['GRPC::BidiCall'].level = :debug

logger = Logger.new(STDOUT, level: :debug)
logger.info("Target server: #{host}:#{port}")

loop do
  stub = Helloworld::Greeter::Stub.new(
    "#{host}:#{port}",
    :this_channel_is_insecure,
  )
  request = Helloworld::HelloRequest.new(name: 'world')

  begin
    logger.info('Sending request')
    res = stub.say_hello(request)
    logger.info("Response: #{res}")
  rescue => e
    logger.warn("Detect error: #{e}")
  end

  sleep(2)
end
