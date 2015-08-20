#!/usr/bin/env ruby
# bgpmon_api_checker.rb
# Ryan C. Moon
# 31 Jul 2013
# Testing SOAP API for bgpmon

require 'savon'

url = 'https://api.bgpmon.net/soap/server.php?wsdl'
user = 'USERNAME_GOES_HERE'
pass = 'PASSWORD_GOES_HERE'
logfile = "/tmp/bgpmon_alerts.new"

class Alert
  def initialize(id,code,name,date,network,as,prefix,origin_as,transit_as)
    @id = id
    @code = code
    @name = name
    @date = date
    @network = network
    @as = as
    @prefix = prefix
    @origin_as = origin_as
    @transit_as = transit_as    
  end  
  
  def display
    return "#{@id}\t#{@code}\t#{@name}\t#{@date}\t#{@network}\t#{@as}\t#{@prefix}\t#{@origin_as}\t#{@transit_as}\n"
  end
end

alerts = Array.new()

client = Savon::Client.new(wsdl: url)
response = client.call(:get_alerts, message: { bgpmon_email: user, bgpmon_password: pass, days: 3 })
response = response.to_hash

# {:alert_id=>"37353361", :alert_code=>"22", :alert_name=>"More Specific", :no_peers=>"1", :date=>"2013-07-31 21:29", :monitored_network=>"209.20.96.0/20", :monitored_as=>"10444", :announced_prefix=>"209.20.100.0/23", :origin_as=>"10444", :transit_as=>"701", :cleared=>false, :"@xsi:type"=>"tns:Alert"}
response[:get_alerts_response][:return][:item].each do |item|
  item = item.to_hash
  alert = Alert.new(item[:alert_id],item[:alert_code],item[:alert_name],item[:date],
                    item[:monitored_network],item[:monitored_as],item[:announced_prefix],item[:origin_as],item[:transit_as])
  alerts << alert
end

File.open(logfile, 'w') do |file| 
  alerts.each do |alert|
    file.write(alert.display)
  end
end
