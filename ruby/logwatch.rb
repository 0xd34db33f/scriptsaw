#!/bin/env ruby
# logwatch.rb
# watches syslog, alerts admin to nonsense, and sets up bans when necessary

require 'file-tail'
require 'rest-client'
require 'daemons'
require 'logger'

watched_file = "/var/log/messages"

# set up logger
log_file = "/var/log/logwatcher.log"
logger = Logger.new(log_file, "daily")
logger.datetime_format = '%b %d %H:%M:%S'

abort "#{watched_file} doesn't exist" unless File.exists?(watched_file) 
abort "#{watched_file} isn't readable" unless File.readable?(watched_file)

class Watcher
  def initialize(name,regex,post,logger)
    @name = name
    @regex = regex
    @post_logs = post
    @logger = logger
    
    # exception SIDS , ignore these
    @exception_sids = []
    @exception_sids << "2001891"  #ET USER_AGENTS Suspicious User Agent (agent) , used by blizzard update agent.

    @logger.info "[+] Initialized Watcher: #{@name} "
  end
  
  def process(line)
    return false if line.nil?
    
    if line.match(@regex)
      @exception_sids.each {|sid| return false if line.match(sid) }
      
      self.log(line) 
      self.post_log(line) if @post_logs
    end
  end
  
  def log(line)
    @logger.info "#{line}"
  end 
  
  def post_log(line)
    status = "success"
    url = "SERVER_URL_TO_LISTENER_GOES_HERE"
    key = "KEY_GOES_HERE"
    
    begin
      response = RestClient.post url, :key => key, :line => line 
    rescue RestClient::ExceptionWithResponse => error
      @logger.info "[!] Failed. Error Code: #{error.response.code} - Attempted to fetch #{url} , but received exception. Badness. Exception: #{error.response} "
    rescue SocketError => error
      @logger.info "[!] Failed. Unknown socket exception occured when fetching url: #{url}. Exception: #{error}"
      status = "failure"
    rescue StandardError => error
      @logger.info "[!] Failed. Unknown standard error occured when fetching url: #{url}. Exception: #{error}"
      status = "failure"
    end
    
    @logger.info "POSTed #{@name} log line to events server: #{line} " if status == "success"
  end
end

# initialize watchers
watchers = Array.new()
# suri event
watchers << Watcher.new("suricata", /suricata/,true,logger)      
# failed ssh login   
watchers << Watcher.new("auth_failure", /authentication failure/,false,logger) 
# successful ssh login                   
watchers << Watcher.new("auth_success",/Accepted password for/,false,logger)    
# new user created                 
watchers << Watcher.new("user_created",/new user\:/,false,logger)
# new group created                     
watchers << Watcher.new("group_created",/new group\:/,false,logger)                                


File.open(watched_file,"rb") do |log|
  log.extend(File::Tail)
  log.interval = 10
  log.backward(10)
  log.tail do |line| 
    watchers.each do |watcher|
      watcher.process(line.chomp!)
    end
  end
end
