#!/usr/bin/env ruby
# dionaea_translator.rb
# Ryan C. Moon
# 2014-12-26
# 
# Reads the sqlite output from dionaea and translates it into basic information JSON

require 'json'

files = {
  "Honeypot1_Name_Goes_Here" => { "filename" => "/tmp/filename_to_read", "ip" => "ip_of_honeypot1"},
	"Honeypot2_Name_Goes_Here" => { "filename" => "/tmp/filename_to_read", "ip" => "ip_of_honeypot2"}
}

# go through each file and pull data
files.each_key do |key|
	filename = files[key]["filename"]
	ip = files[key]["ip"]
	lines = []
	output = {
		"origin" => "Organized Villainy #{key} Honeypot - #{ip} - Daily Attack Feed",
		"disclaimer" => "By using this system in any capacity or capability you release all claims of damages and shall not hold or perceive any liability against the publisher for: damage, unexpected events or results, decision, or reputation damage, even those resulting from wilful or intentional neglect. No claims made against this data shall be honored; no assertions have been made about the quality, accuracy, usability, actionability, reputation, merit, or hostility of the returned findings. Use the return results at your own risk."
	}
	
	# copy our data into memory so we can overwrite the file
	File.open(filename,"r").each_line {|line| lines << line }

	# lines look like this:
	# 1|accept|tcp|ftpd|1419432133.85313|1||107.191.117.147|21|98.33.241.19||54238
	lines.each do |line|
	  
		data = line.split("|")
		next unless data.size > 5
		
		# assign the data to more usable descriptors
		protocol = data[2]
		service = data[3]
		src_ip = data[9]
		dst_port = data[8]
	  
	  # check to ensure we have an actual IP address
	  next unless src_ip.match(/^([0-9]{1,3}\.){3}[0-9]{1,3}$/)
	  
	  # we want to sort our data into unique hash keys and keep track of ports there.
	  # "attacker_ip" => { "port_80" => {"count" => 1, "port" => "80", "protocol" => "tcp", "service" => "service" } , "port_443" => {..}}
	  if output.has_key?(src_ip) 
	    if output[src_ip].has_key?("port_#{dst_port}")
	      # increment a port entry
	      output[src_ip]["port_#{dst_port}"]["count"] += 1
	    else
	      # create a new port entry for an existing IP
	      output[src_ip]["port_#{dst_port}"] = {"count" => 1, "target_port" => dst_port, "protocol" => protocol, "service" => service }
	    end
	  else
	    # create a new IP entry
		  output[src_ip] = { } 
		  output[src_ip]["port_#{dst_port}"] = {"count" => 1, "target_port" => dst_port, "protocol" => protocol, "service" => service }
		end
	end
	
	# Now dumbly convert the output to JSON by hand cause of our line-requirements on Holmes, then write file out
	writable = ""
	writable += "{\n"
	writable += "\t\"origin\":\""+output["origin"]+"\",\n"
	writable += "\t\"disclaimer\":\""+output["disclaimer"]+"\",\n"
	writable += "\t\"content\": [\n"
	output.keys.each do |key|
	  next if key == "origin" || key == "disclaimer"
	  
	  output[key].keys.each do |k|
	    next unless output[key][k].has_key?("count")
	  
	    writable += "\t{ \"count\": \"" + output[key][k]["count"].to_s 
	    writable += "\", \"attacker_ip\": \"" + key.to_s
	    writable += "\", \"target_port\": \"" + output[key][k]["target_port"].to_s 
	    writable += "\", \"protocol\": \"" + output[key][k]["protocol"] 
	    writable += "\", \"service\": \"" + output[key][k]["service"] 
	    writable += "\" },\n"
	  end
	end
	# remove the , at the end of the last entry
	writable.chop!.chop!
	writable += "\n\t]\n}\n"
	
	File.open(filename+".feed","w") {|f| f.write(writable) }
end
