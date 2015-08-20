#!/home/www-data/.rvm/rubies/ruby-2.1.0/bin/ruby -n
# dhcp_watcher.rb
# Ryan C. Moon
# 2015-05-13
# the -n ruby switch treats your entire script as a loop over the input.
# Watches tcpdump for DHCPACK frames and regexes them for matching ip/hostname pairs. 
# command: /usr/sbin/tcpdump -i eth0 -l -Anns0 port 514 | grep --line-buffered "DHCPACK" | /home/rest/scripts/dhcp_watcher.rb

require 'rest-client'

debugging = 0

line = $_
$HOSTNAME_REGEX = /[A-Z0-9-]+/
$IP_REGEX = /([0-9]{1,3}\.){3}[0-9]{1,3}/
$REST_API_URL = ""
  
begin
  # retrieve the line and try to split it.
  next unless line.match($IP_REGEX) 
  data = line.chomp.split(/\x09/)
  data.inspect
  host = data[5]
  ip = data[3]
  
  next unless host.match($HOSTNAME_REGEX)
  next unless ip.match($IP_REGEX)
  print "Found data: host = #{host} / ip = #{ip} \n" if debugging > 0
  
  # post the data to the Redis REST API
  url = "#{$REST_API_URL}/#{ip}"
  user_agent = 'MSK/ThePunchifier++'
  results = RestClient.post url, {:ip => ip, :hostname => host }, :user_agent => user_agent
rescue
  print "[ERROR] Something stupid happened..\n"
end
