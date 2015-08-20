#!/Users/crash/.rvm/rubies/ruby-1.9.3-p385/bin/ruby
# server_monitor.rb
# Ryan C. Moon
# 01 Aug 2013
# Grabs some quick and dirty vital statistics for a server for a report

require 'net/ssh'

user = 'USERNAME_GOES_HERE'
hosts = ["192.168.1.1","192.168.1.2"]
key = '/tmp/id_dsa'

class Server
  def initialize(ip,hostname,uptime,df)
    @ip = ip
    @hostname = hostname.chomp
    @uptime = uptime.chomp
    @df = df

    # storage volume utilization
    @volumes = Hash.new    
    @df.each_line do |line|
      volume_name = line.split(" ")[1]
      volume_usage = line.split(" ")[0]
      @volumes[volume_name] = volume_usage
    end
    
    # cpu load calculations
    tmp = uptime.split(" ")
    @one_minute_cpu_average_load = tmp[-3].chop
    @five_minute_cpu_average_load = tmp[-2].chop
    @fifteen_minute_cpu_average_load = tmp[-1]
  end
  
  def display
    print "#{@ip}\n"
    print "\t#{@hostname}\n"
    print "\t#{@uptime}\n"
    print "\tDisk Usage:\n"
    @volumes.each do |k,v|
      print "\t\t#{v}\t#{k}\n"
    end
    
    print "\tCPU Usage:\n"
    print "\t\t1min Average:\t#{@one_minute_cpu_average_load}\n"
    print "\t\t5min Average:\t#{@five_minute_cpu_average_load}\n"
    print "\t\t15min Average:\t#{@fifteen_minute_cpu_average_load}\n"
    
    print "\n"
  end
end
    
    

hosts.each do |host|

  Net::SSH.start(host, user, :keys => [key]) do |ssh|
    hostname = ssh.exec!("hostname")
    uptime = ssh.exec!("uptime")
    df = ssh.exec!("df -Ph | column -t | grep \"%\" | awk '{print $5 \" \" $6}' | grep -v 'Use%'")
    
    server = Server.new(host,hostname,uptime,df)
    server.display
  end
end
