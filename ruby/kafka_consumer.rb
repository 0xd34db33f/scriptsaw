#!/usr/bin/env ruby
# Requires poseidon gem: https://github.com/bpot/poseidon
# Reads the kafka log at the server/topic of our choice, prints it to STDOUT.
# Just a super basic consumer to test your setup.
# MUST BE POINTED AT THE LEADER OF THE KAFKA TOPIC PARTITION ( ~/src/kafka_2.10-0.8.2.0/bin/kafka-topics.sh --describe --zookeeper localhost:2181 --topic #{topic} )

require 'poseidon'

TOPIC="test-replicated-topic"
LEADER_SERVER = "localhost"
LEADER_PORT = "9093"

consumer = Poseidon::PartitionConsumer.new("my_test_consumer", LEADER_SERVER, LEADER_PORT, TOPIC, 0, :earliest_offset)

loop do
  messages = consumer.fetch
  messages.each do |m|
    puts m.value
  end
end
