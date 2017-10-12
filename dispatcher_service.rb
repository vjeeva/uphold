module Uphold
  require 'rubygems'
  require 'rubygems/package'
  require 'bundler/setup'
  Bundler.require(:default, :dispatcher)
  load 'environment.rb'

  Config.load_message_queues

  dispatcher = Dispatcher.new(Config.load_message_queues_config)
  dispatcher.start
end