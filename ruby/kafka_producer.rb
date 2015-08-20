#!/usr/bin/env ruby
# Requires poseidon gem: 
# This takes our STDIN arguments and passes them as messages to the kafka topic log.
# Just a super basic kafka producer to test your setup.

require 'poseidon'

producer = Poseidon::Producer.new(["localhost:9091"], "my_test_producer")

messages = []
ARGV.each {|m| messages << Poseidon::MessageToSend.new("test-replicated-topic", m) } 
producer.send_messages(messages)
