#!/usr/bin/env ruby
# generic_downloader.rb - written as a skeleton for feed handling, mimics MSIE 8.0.
# 2015-02-24
# Built to be run at 2359 via cronjob.

require "rest-client"
require "nokogiri"

TODAY=Time.now.strftime("%Y-%m-%d")
FILETYPE="gz"
SAUCE="NAME_GOES_HERE"
URL="URL_GOES_HERE"


# grab the artifact
begin
  artifact = RestClient.get URL, :user_agent => "Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 1.1.4322; .NET CLR 2.0.50727; .NET4.0E; .NET4.0C)"
rescue RestClient::ExceptionWithResponse => error
  print "[!] Failed. Error Code: #{error.response.code} - Attempted to fetch #{URL} , but received exception. Badness. Exception: #{error.response.slice(0,1000)}\n"
  exit 1
rescue SocketError => error
  print "[!] Failed. Unknown socket exception occured when fetching url: #{URL}. Exception: #{error.inspect.slice(0,1000)}"
  exit 1
rescue StandardError => error
  print "[!] Failed. Unknown standard error occured when fetching url: #{URL}. Exception: #{error.inspect.slice(0,1000)}"
  exit 1
end

# We have a response, lets see if it's a valid one by checking RFC 2616 response codes
if artifact.code != 200 
  print "[!] Failed. Attempted to fetch #{URL} , but received non-200 HTTP response code, #{artifact.code}. Badness. Response: #{artifact.slice(0,1000)} "
  exit 1
end

# does our response have data?
if artifact.size == 0 
  print "[!] Failed. Attempted to fetch #{URL} , but received empty response. Response: #{artifact.slice(0,1000)} "
  exit 1
end

data = nil

# artifact now contains our data
if FILETYPE == "gz"
  data = Zlib::GzipReader.new(StringIO.new(artifact)).read
elsif FILETYPE == "zip"
  data = ""
elsif FILETYPE == "7z"
  data = ""
else
  data = artifact
end

  
# now write data to our file in /tmp
File.open("/tmp/#{SAUCE}_output.txt", "w") {|f| f.write(data) }




