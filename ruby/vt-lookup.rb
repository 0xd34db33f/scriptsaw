#!/usr/bin/env ruby
# vt-lookup.rb
# Ryan C. Moon
# 24 Sept 2013
# Feed a hash, get a VT result via the public API
# ex: ./vt-lookup.rb -h ebd766d640a70f21b10dfdf2eb5126efdd8e31b2e7d2c83ca0e23f5177c22b28
#
# Requirements, Gems, Config Notes, Advice:
# Gem requirements: rest-client, json
# This script was built for OSX/Ubuntu/RHEL Linux. 
# Change the options[:file_command] path to work with any other GNU-based OS.

require "rest-client"
require 'json'
require 'digest'

PATTERN_CMND_ARGS = %r{-[yfhv]}
options = { 
  :uri => "https://www.virustotal.com/vtapi/v2/file/report",
  :key => "KEY_GOES_HERE",
  :file_lookup => false,
  :hash_lookup => false, 
  :debugging => false,
  :upload_files => false,
  :filename => '',
  :hash => '',
  :file_command => '/usr/bin/file',
  :acceptable_mime_types => ["application/octet-stream","application/x-msi","application/vnd.ms-office"]
}

###### Objects #############

# VT model
class VT

  def initialize(hash,filename,uri,key)
    @uri = uri
    @key = key
    @hash = hash
    @filename = filename
    @successful = false
    @response = RestClient.post uri, { :resource => hash, :key => key }
    @results = JSON.parse(@response)
    @scans = Array.new()
    
    # was this successful?
    if @results.has_key?('response_code') && @results['response_code'] == 1
      @successful = true
    
    # our file might just be unknown
    elsif @results.has_key?('verbose_msg') && @results['verbose_msg'].match(/The requested resource is not among the finished, queued or pending scans/)
      # NOP
      # this will cause a blank engines hash which is detected later.
      
    # something went wrong
    else
      print "[!] VirusTotal API did not like our submission.\n"
      print "Error hash: #{@results.inspect}\n"
      abort
    end
    
    # did we submit a new file? if so, this hash will be empty.
    # Previously uploaded file
    if @results.has_key?("scans") && @results['scans'].size > 0
      @results['scans'].each { |av_engine| @scans << Scan.new(av_engine) }
    
    # new file
    else 
      @results['scans'] = Hash.new()
    end    
  end
  
  def scans
    @scans
  end
  
  def filename
    @filename
  end
  
  # counts # of detections based on engines with detection marked true.
  def detections
    detections = 0
    
    @scans.each do |engine|
      detections += 1 if engine.detected
    end
    
    return detections
  end
  
  def engines
    @scans.size
  end
  
  def detection_rate
    return "#{self.detections}\/#{self.engines}"
  end
  
  # if we have 0 engines, that means the file has never been analyzed
  def unknown_file
    self.engines == 0 ? true : false
  end
  
  # uploads the file to VT if we have a file.
  def upload_file
    uri = 'https://www.virustotal.com/vtapi/v2/file/scan'
    file_to_send = open(self.filename, "rb").read()
    files = ["file",self.filename,file_to_send]
    response = RestClient.post uri, { :key => @key, :payload => { :multipart => true }, :file => File.new(self.filename, 'rb') }
    results = JSON.parse(response)
    
    # inspect our return codes from the API
    if results.has_key?('response_code') && results['response_code'] == 1
      print "File successfully uploaded to VirusTotal via API.\n"
      print "Link: #{results['permalink']} \n"
    else
      # due to possible link failure, firewall block, bad request, API changes, we can't trust this hash. Inspect it.
      print "VirusTotal API did not like our submission.\n"
      print "Error hash: #{results.inspect}\n"
      abort
    end
  end
end

class Scan
  
  # each scan entry is an array with the first token being the scan engine name, the second being a hash of the detections.
  # ex: ["nProtect", {"detected"=>false, "version"=>"2012-08-06.01", "result"=>nil, "update"=>"20120806"}]
  def initialize(scan_object)
    @engine = scan_object[0]
    @detected = scan_object[1]['detected']
    @version = scan_object[1]['version']
    @result = scan_object[1]['result']
    @update = scan_object[1]['update']
  end
  
  def engine
    @engine
  end
  
  def detected
    @detected
  end
  
  def version
    @version
  end
  
  def update
    @update
  end
end

## Methods ############

def print_help_and_exit
  print "NAME\n\tvt-lookup.rb - Feed it a hash, get a VT result via the public API. \n\n"
  print "SYNOPSYS\n\tvt-lookup.rb [-h hash] [-f file] -v\n\n"
  print "DESCRIPTION\n"
  print "\tVirusTotal API query tool for hashes from command line. Useful for scripting or \n"
  print "\tother plug-in detection systems where you have an API key capable of taking the \n"
  print "\tvolume your script will generate.\n\n"
  print "OPTIONS\n\t-f\tSets vt-lookup.rb to check a file, this will generate a hash and \n"
  print "\t\tcheck that against the VT API. These *cannot* be combined ala '-fvy'.\n"
  print "\n\t-h\tSets vt-lookup.rb to check a hash against the VT API.\n"
  print "\n\t-v\tSets verbose output. Must be the last option.\n"
  print "\n\t-y\tUpload any unknown files that are executables, jars, or zips.\n\n"
  abort
end

def parse_command_arguments(args,options)
  # ex: args: ["-v", "bad.file","-f","/tmp/file","-h","abcdef0918218717139"]
  
  if args.size < 2 
    print_help_and_exit()
  end
  
  # check for verbose debugging flag
  if args.include?('-v')
    options[:debugging] = true
  end
  
  # check for file upload == yes flag
  if args.include?('-y')
    options[:upload_files] = true
  end
  
  if args.include?('-h')
    options[:hash_lookup] = true
    
    # find the hash, there should be only one non-switch
    args.each {|a| options[:hash] = a if !a.match(PATTERN_CMND_ARGS)}
    
    # validate we found a hash
    if options[:hash] == ''
      print "[!] Option for hash lookup activated, -h, but no hash found on command line.\n"
      print_help_and_exit()
    end     
      
  elsif args.include?('-f')
    options[:file_lookup] = true
    
    # find the filename, there should be only one non-switch
    args.each {|a| options[:filename] = a if !a.match(PATTERN_CMND_ARGS)}
    
    # validate we found a file
    if options[:filename] == ''
      print "[!] Option for hash lookup activated, -h, but no hash found on command line.\n\n"
      print_help_and_exit()
    end
    
    # extract hash
    if File.exists?(options[:filename]) && File.file?(options[:filename]) && File.readable?(options[:filename]) && !File.size?(options[:filename]).nil?
      options[:hash] = Digest::SHA256.hexdigest(File.new(options[:filename]).read)
    else
      # filename is pointing to something strange.
      print "[!] Unrecognized option: #{args.join(' ')}, this is either pointing at a non-file (link/directory),\n"
      print "a file of 0 size, or is inaccurately formed. Please consult the helpful information below.\n\n"
      print_help_and_exit()
    end
  else
    # we're not doing anything?
    print "[!] Unrecognized option: #{args.join(' ')}, you neither specified a hash or file lookup.\n\n"
    print_help_and_exit()
  end  
end


## Main #################

parse_command_arguments(ARGV,options)

# get hash from command line arguments
print "Checking hash: #{options[:hash]} \n" if options[:debugging]

result = VT.new(options[:hash], options[:filename], options[:uri], options[:key])

# upload unknown files of the right "type", this avoids PII problems if you stick to exes and jars.
# Jars appear as zips to filemagic/file command, so we cannot upload these. We have to search for them via regex.
if result.unknown_file && options[:file_lookup] && options[:filename] != '' && options[:upload_files]
  mime_type = IO.popen([options[:file_command], "--brief", "--mime-type", options[:filename]], in: :close, err: :close).read.chomp
  print "File mime-type: #{mime_type} \n" if options[:debugging]
  
  # if the mime_type/file extension is on our list, upload it.
  if options[:acceptable_mime_types].include?(mime_type)||options[:filename].match(/\.(jar|exe)$/)
    result.upload_file  
  else
    print "Declining to upload file due to unauthorized mime-type or file extension.\n" if options[:debugging]
  end
end

if options[:debugging]
  # get detection rate
  print "#{result.detection_rate} detections \n\n"
  
  # report engine status
  longest_name = 0
  result.scans.each { |engine| longest_key = engine.engine.length if engine.engine.length > longest_name }
  
  printf "%-25s %-16s\t%-16s\t%-16s\n","Engine", "Detection","Version","Date"
  printf "%-25s %-16s\t%-16s\t%-16s\n","------", "---------","-------","----"
  result.scans.each do |engine|
    #print "#{engine.detected}\t#{engine.version}\t#{engine.update}\t#{engine.engine}\n"
    printf "%-25s %-16s\t%-16s\t%-16s\n", engine.engine, engine.detected, engine.version, engine.update
  end
  
  # report url
  print "\nVT URL -- https://www.virustotal.com/en/file/#{options[:hash]}/analysis/\n\n"
end

if result.unknown_file
  print "File unknown to VT.\n"  
else
  print "#{result.detection_rate}\n"
end

