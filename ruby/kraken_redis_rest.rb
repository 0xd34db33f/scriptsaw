#!/usr/bin/env ruby
# kraken_redis_rest.rb
# Ryan C. Moon
# 2015-05-06
#
# Redis REST API via Sinatra
# Built for Kraken Big Data Store for IP address intel, nothing complex.

require 'sinatra'
require 'json'
require 'redis'
require 'redis-namespace'

enable :logging
set :port, SERVER_PORT_GOES_HERE
set :bind, "SERVER_NAME_GOES_HERE"

configure do
  redis_conf = { :host => "127.0.0.1", :port => "SERVER_PORT_GOES_HERE", :password => "REDIS_PASSWORD_GOES_HERE" }
  @@redis = Redis.new redis_conf
  
end

before do
  @title = "Kraken Redis REST API"
end

get '/:filter' do
  @@redis.get params[:filter]
end

get '/' do
  "Kraken Redis REST API\n"
  "\tFormat: http://:host/:filter\n"
  "\tExample: http://127.0.0.1/172.6.192.161\n"
end

get '*' do
  "404 - " +request.ip + ", do you know what you are doing?\n"
end
