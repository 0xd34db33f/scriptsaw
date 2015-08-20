#!/usr/bin/env ruby
# unified_file_watcher.rb
# Ryan C. Moon
# 2014-04-30
# Watches /var/log/suricata/* for unified2.alert.* files, then starts the unified log watcher when they appear.


# The first thing we do, let's kill all the log watchers.
# Nay, that I mean to do.
log_watcher_pids = %x(ps aux | grep ruby | grep unified2syslog.rb | grep -v grep | awk '{print $2}').split(/\n/)

if log_watcher_pids.size > 0
  log_watcher_pids.each do |pid|
    kill_command = %x(kill -9 #{pid})
  end
  
  log_watcher_pids = %x(ps aux | grep ruby | grep unified2syslog.rb | grep -v grep | awk '{print $2}').split(/\n/)
  abort "Could not kill all the unified2syslog pids!" if log_watcher_pids.size > 0
end

# 
log_dirs = Dir.entries("/var/log/suricata")
prospective_files = Array.new()
active_files = Array.new()

while(true)
  # Get all our files
  log_dirs.each do |dir|
    next if dir == ".."
    Dir.entries("/var/log/suricata/"+dir).each do |file|
      filename = "/var/log/suricata/"+dir+"/"+file
      prospective_files << filename if file.match(/unified2.alert.[0-9]+$/) && !prospective_files.include?(filename)
    end
  end
  
  prospective_files.each do |file|
    # A wild unified2.alert log file appears!
    if !active_files.include?(file)
      active_files << file
      p "activating on file: #{file}.."
      %x( /root/scripts/unified2syslog.rb #{file} & )
    end
  end
  
  # ask suricata's which files they are currently writing too
  active_files.each do |file|
    active_count = %x( /usr/bin/lsof #{file} | wc -l ).chomp!.to_i
    if active_count == 0
      p "File #{file} no longer a part of an active Suricata, killing off."
      File.unlink(file) if File.exists?(file)
    end
  end
  
  sleep 30
end
