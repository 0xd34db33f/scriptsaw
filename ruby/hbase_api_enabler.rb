#!/usr/bin/env ruby
# hbase_api_enabler.rb
# Ryan C. Moon (@ryancmoon|ryan@organizedvillainy.com)
# 2015-10-06
# Works with your HBase API to add/remove data, create/remove tables, etc.
# HBase API Reference: https://hbase.apache.org/apidocs/org/apache/hadoop/hbase/rest/package-summary.html
# HBase storage reference: http://0b4af6cdc2f0c5998459-c0245c5c937c5dedcca3f1764ecc9b2f.r43.cf2.rackcdn.com/9353-login1210_khurana.pdf

### Libs/gems
require "base64"
require "rest-client"
require "json"
require "yaml"

### Constants and globals
VERSION="0.5"
DEBUG = 0
HBASE_SERVER = ""
HBASE_PORT = ""
options = { 
  'user_agent' => "Ruby/HBase API CLI Enabler #{VERSION}"
}


### functions

def usage(message)
  print "#{message}\n\n" unless message.empty?
  
  print "hbase_api_enabler.rb \n"
  print "GPLv3 - 2015-10-06 \n"
  print "by Ryan C. Moon (@ryancmoon|ryan@organizedvillainy.com) \n"
  print "\n"
  print "Usage: ./hbase_api_enabler.rb <HBASE VERB> <OPTIONS> \n"
  print "\t**BE CAREFUL USING THIS TOOL, IT WILL NOT BABYSIT YOU** \n"
  print "\tThis tool is for reading text/ascii, it will print nonsense \n"
  print "\t  to your console if you query for binary data. \n"
  print "\n"
  print "\tValid HBASE VERBS: GET_TABLES CREATE_TABLE DROP_TABLE GET_SCHEMA \n"
  print "\t  GET_ROW ADD_ROW DELETE_ROW GET_VALUE ADD_VALUE DROP_VALUE SCAN\n"
  print "\n"
  print "\tOPTIONS:\n"
  print "\t\t * means check the notes below. \n"
  print "\t\tGET_TABLES (no options required) \n"
  print "\t\tCREATE_TABLE <table name> <schema family name>\n"
  print "\t\tDROP_TABLE <table name> \n"
  print "\t\tGET_SCHEMA <table name> \n"
  print "\t\tADD_VALUE <table name> <row key> <column family> <column name> <value> \n"
  print "\t\tGET_VALUE <table name> <row key> <column family> <column name> \n"
  print "\t\tADD_ROW <table name> <row key> <column family> <column hash*> \n"
  print "\t\tDELETE_ROW <table name> <row key> \n"
  print "\t\tGET_ROW <table name> <row key>\n"
  print "\t\tSCAN <table name> <limit> <row prefix> <column list (optional)*> \n"
  print "\n"
  print "\tNotes:\n"
  print "\tThe {}'s & \"'s are important, this is JSON parsed input. \n\n"
  print "\tColumn Hash example (json) : \n\t'{\"column_name_1\":\"column_value_1\", \"column_name_2\":\"column_value_2\" }' \n\n"
  print "\tColumn List example (json) : \n\t'{\"columns\":[\"family:column a\",\"family:column b\",\"family:column c\"]}' \n"
  print "\n\n"
  
  abort()
end

def startup_options(options)
  if ARGV[0].nil?
    usage("[!] Error parsing command line arguments.")
  end
  
  options['hbase_verb'] = ARGV[0]
  
  case ARGV[0]
  
  # GET_TABLES
  # Outputs the table names
  when "GET_TABLES"
    # No args required.
    
  # CREATE_TABLE <table name> <table schema name> <schema hash*>
  # Will create just the schema if the table already exists.
  when "CREATE_TABLE"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    
    options['table_name'] = ARGV[1]
    options['table_schema_name'] = ARGV[2]
    #options['table_schema'] = parse_json(ARGV[3])  
  
  # DROP_TABLE <table name>
  when "DROP_TABLE" 
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2    
    options['table_name'] = ARGV[1]
  
  when "GET_SCHEMA"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2    
    options['table_name'] = ARGV[1]
      
  when "GET_ROW" 
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    options['table_name'] = ARGV[1]
    options['row_key'] = ARGV[2]
    
  when "ADD_ROW"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 5
    options['table_name'] = ARGV[1]
    options['row_key'] = ARGV[2]
    options['column_family'] = ARGV[3]
    options['column_hash'] = JSON.parse(ARGV[4])
    
  when "DELETE_ROW"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    options['table_name'] = ARGV[1]
    options['row_key'] = ARGV[2]
    
  when "GET_VALUE" 
    usage("[!] Error parsing command line arguments.") if ARGV.size < 5
    options['table_name'] = ARGV[1]
    options['row_key'] = ARGV[2]
    options['column_family'] = ARGV[3]
    options['column_name'] = ARGV[4]
    
  # ADD_VALUE <table name> <row_key> <column hash*>
  when "ADD_VALUE"
    usage("[!] Error parsing command line arguments. Not enough arguments..") if ARGV.size < 6
  
    options['table_name'] = ARGV[1]
    options['row_key'] = ARGV[2]
    options['column_family'] = ARGV[3]
    options['column_name'] = ARGV[4]
    options['column_value'] = ARGV[5]
    
  when "DROP_VALUE"

  when "SCAN"
    usage("[!] Error parsing command line arguments. Not enough arguments..") if ARGV.size < 4
    
    options['table_name'] = ARGV[1]
    options['limit'] = ARGV[2]
    options['row prefix'] = ARGV[3]
    options['columns'] = parse_json(ARGV[4])['columns'] if ARGV.size > 4
    
  else
    usage("[!] An unknown error occurred. Arguments could not be parsed, Arguments Array = #{ARGV}")
  end
end

# encode : All values are stored in base64, we need to encode them.
def encode(value)
  Base64.encode64(value).chomp
end

# decode : pull values from the database and parse into english
def decode(value)
  Base64.decode64(value).chomp
end

# parses json or dies
def parse_json(data)
  begin
    returnable = JSON.parse(data)
  rescue => e
    print "[!] Failed. Could not parse JSON. Data: #{data} \n"
    abort
  end
end

# parses results into YAML or dies
def parse_yaml(data)
  begin
    returnable = YAML.load(data)
  rescue => e
    print "[!] Failed. Could not load YAML. Data: #{data} \n"
    abort
  end
end

# Gets all the table names and returns them in JSON format.
def get_tables(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/"
  
  begin 
    print "[attempting] GET Table names via #{options['url']} \n" if DEBUG > 0
    results = RestClient.get options['url'], { :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
end

# Creates a table
# POST /<table>/schema
def create_table(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options["table_name"]}/schema"
  
  begin
    data = {"@name"=>  options['table_name'], "ColumnSchema"=>[{"name"=> options['table_schema_name']}]}
    print "[attempting] Create Table via POST to #{options['url']} with data: #{JSON.dump(data)} \n" if DEBUG > 0
    results = RestClient.post options['url'], JSON.dump(data), { :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 201
    print "[success] Created new table: #{options['table_name']} \n"
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# deletes a table
def delete_table(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options["table_name"]}/schema"
  
  begin
    results = RestClient.delete options['url'],{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[success] Deleted table: #{options['table_name']} \n"
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# get the schema for a table
# GET /<table>/schema
def get_schema(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options["table_name"]}/schema"
  
  begin
    data = {"@name"=>  options['table_name'], "ColumnSchema"=>[{"name"=> options['table_schema_name']}]}
    print "[attempting] GET table schema via #{options['url']} \n" if DEBUG > 0
    results = RestClient.get options['url'], { :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[success] Table schema: #{options['table_name']} = #{results} \n"
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# store value in a table
# ADD_VALUE <table name> <row_key> <column key> <column value>
# POST /<table>/<row>/<column>( : <qualifier> )? ( / <timestamp> )?
# This will overwrite the value if the value already exists.
def add_value(options)
  
  full_column_name = "#{options['column_family']}:#{options['column_name']}"
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options['table_name']}/#{options['row_key']}/#{full_column_name}"
  
  data = JSON.dump(
    {"Row" =>
    [     
      {
        "key" => encode(options['row_key']), 
        "Cell" => [
          {"column" => encode(full_column_name), "$" => encode(options['column_value'])}
        ]
      }
    ]
  })
  
  begin
    print "[attempt] PUT'ing URL: #{options['url']}.. with full_column_name: #{full_column_name} and data: #{data} \n" if DEBUG > 0
    results = RestClient.post options['url'],data,{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[success] Added value: #{data} \n"
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# GET_VALUE
# GET /<table name>/<row key>/<column family>:<column name>
def get_value(options)
  full_column_name = "#{options['column_family']}:#{options['column_name']}"
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options['table_name']}/#{options['row_key']}/#{full_column_name}"
  
  begin
    print "[attempt] GET value data via #{options['url']}.. with full_column_name: #{full_column_name}\n" if DEBUG > 0
    results = RestClient.get options['url'],{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[returned] value:\n#{results} \n" if DEBUG > 0
    print "[success] Value:\n"
    result_set = parse_yaml(results)
    if result_set.has_key?('Row')
      print '{"' + options['column_name'] + '":"' + Base64.decode64(result_set['Row'][0]['Cell'][0]['$']) + '"}' + "\n"
    end
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# ADD_ROW
# POST /<table name>/<row key>
def add_row(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options['table_name']}/#{options['row_key']}"
  
  data = { "Row" => 
        [
          "key" => encode(options['row_key']),
          "Cell" => [
            
          ]
        ]
      }
    
  options['column_hash'].keys.each do |key|
    column_encoded = encode(options['column_family']+":"+key)
    value_encoded = encode(options['column_hash'][key])
    data["Row"][0]["Cell"] << { "column" => column_encoded, "$" => value_encoded }
  end
  
  begin 
    print "[attempt] POST row data via #{options['url']} with data: #{JSON.dump(data)}..\n" if DEBUG > 0
    results = RestClient.post options['url'], JSON.dump(data),{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[success] Created new row: #{data} \n"
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# DELETE_ROW
# DELETE /<table name>/<row key>
def delete_row(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options['table_name']}/#{options['row_key']}"
  
  begin 
    print "[attempt] DELETE row data via #{options['url']}..\n" if DEBUG > 0
    results = RestClient.delete options['url'],{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[success] Deleted row: #{options['row_key']} \n"
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# GET_ROW
# GET /<table name>/<row key>
def get_row(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options['table_name']}/#{options['row_key']}"
  
  begin 
    print "[attempt] GET row data via #{options['url']}..\n" if DEBUG > 0
    results = RestClient.get options['url'],{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue RestClient::ResourceNotFound => error
    # row doesn't exist, 404 response code with "Not found" in message body. This is not a bad thing.
    print "[success] Row: \n {}\n"
    abort
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[returned] value:\n#{results} \n" if DEBUG > 0
    print "[success] Row: \n"
    result_set = parse_yaml(results)
    if result_set.class == Hash && result_set.has_key?('Row') && result_set['Row'].class == Array && result_set['Row'][0].has_key?('Cell')
      rows = []
      
      result_set['Row'][0]['Cell'].each do |column|
        rows <<  '"' + Base64.decode64(column['column']).split(":")[1] + '":"' + Base64.decode64(column['$']) + '"'
      end
      print "{" + rows.join(",") + "}\n"
    end
    
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end


# SCAN
def scan(options)
  options['url'] = "http://#{HBASE_SERVER}:#{HBASE_PORT}/#{options['table_name']}/#{options['row_prefix']}*?limit=#{options['limit']}"
  
  if !options['columns'].nil?
    options['url'] += "&" + CGI.escape(options['columns'].join(","))
  end
  
  begin 
    print "[attempt] SCAN for rows via #{options['url']}..\n" if DEBUG > 0
    results = RestClient.get options['url'],{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    print "[success] Results: #{results} \n" if DEBUG > 0
    
    # Results is now a hash with base64 values in it, decode and JSON.
    result_set = parse_json(results)
    result_lines = []
    if result_set.class == Hash && !result_set['Row'].nil?
      
      result_set['Row'].each do |row|
        result_rows = []
        result_rows << "\"key\":\"" + Base64.decode64(row['key']) + "\""
        row['Cell'].each do |cell|
          result_rows << "\"" + Base64.decode64(cell['column']) + "\":\"" + Base64.decode64(cell['$']) + "\""
        end
        result_lines << "{" + result_rows.join(",") + "}"
      end
      
      print result_lines.join(",\n") + "\n"
      
      # keys = result_set['Row'].collect { |row| Base64.decode64(row['key']) }
      # cells = result_set['Row'].collect { |row| row['Cell'] }
    end
  else
    print "[failure] HBase REST API returned a strange result: #{results} \n"
    abort
  end
end

# rest_action : the meat of the application
def rest_action(options)
  
  results = ""
  
  case options['hbase_verb']
    
  when "GET_TABLES"
    results = get_tables(options)
  when "CREATE_TABLE"
    results = create_table(options)
  when "DROP_TABLE"
    results = delete_table(options)
  when "GET_SCHEMA"
    results = get_schema(options)
  when "GET_ROW"
    results = get_row(options)
  when "ADD_ROW"
    results = add_row(options)
  when "DELETE_ROW"
    results = delete_row(options)
  when "GET_VALUE"
    results = get_value(options)
  when "ADD_VALUE"
    results = add_value(options)
  when "DROP_VALUE"
  
  when "SCAN"
    results = scan(options)
  else
    print "[!] REST API Verb not recognized: #{options['hbase_verb']} \n"
    abort
  end

  return results
end
  
### Main sequence
startup_options(options)

print rest_action(options)
print "\n"
