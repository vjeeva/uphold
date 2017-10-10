module Uphold
  require 'rubygems'
  require 'rubygems/package'
  require 'bundler/setup'
  Bundler.require(:default, :dispatcher)
  load 'environment.rb'

  dispatcher = Dispatcher.new
  dispatcher.start
end