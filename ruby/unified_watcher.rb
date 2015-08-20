#!/usr/bin/env ruby
# unified_watcher.rb
# Ryan C. Moon
# 2014-06-12
# watches unified2 log, translates LBPub alerts into real alerts, transmits to syslog

require 'unified2'
require 'syslog/logger'

watched_file = ARGV[0]

# set up logger
log = Syslog::Logger.new 'suricata'

#abort "#{watched_file} doesn't exist" unless File.exists?(watched_file) 
#abort "#{watched_file} isn't readable" unless File.readable?(watched_file)

Unified2.configuration do

  load :signatures, '/usr/suricata/rules/sid-msg.map'
  load :generators, '/usr/suricata/rules/gen-msg.map'
  load :classifications, '/usr/local/etc/suricata/classification.config'

end

def start_unified(watched_file,log)
  pos = 0
  abort = false
  size = File.size(watched_file)
  new_size = size

  while (!abort)
    Unified2.read(watched_file, pos) do |event|
      #log.error "[1:#{event.event.data.signature_id}:1] #{event.signature.name} [Classification: #{event.classification.name}] [Priority: #{event.event.data.priority_id}] {#{event.protocol}} #{event.event.data.ip_source}:#{event.event.data.sport_itype} -> #{event.event.data.ip_destination}:#{event.event.data.dport_icode}"  
      
      # use X-Forwarded For?
      ip_source = event.event.data.ip_source
      #
      event.packets.each do |packet|
        packet.raw.headers.each do |header|
          header.body.to_s.split("\r\n").each do |line| 
            ip_source = line.split(/:/)[1]  if line.match(/X-Forwarded-For:/)
          end
        end
      end
            
      log.error "[1:#{event.event.data.signature_id}:1] #{event.signature.name} [Classification: #{event.classification.name}] [Priority: #{event.event.data.priority_id}] {#{event.protocol}} #{ip_source}:#{event.event.data.sport_itype} -> #{event.event.data.ip_destination}:#{event.event.data.dport_icode}"  
        
    end

    size = new_size
    while(size == new_size && !abort)
      abort = true unless File.exists?(watched_file)
      new_size = File.size(watched_file) unless abort
      sleep 5
    end  
  end
end

start_unified(watched_file,log)




  
  

