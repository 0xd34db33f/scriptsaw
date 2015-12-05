#!/usr/bin/env ruby
# openfire_api_helper.rb
# Ryan C. Moon (@ryancmoon/ryan@organizedvillainy.com)
# 2015-12-04
# Acts as a command line interface using Redeyes' open REST API plugin. 
# Reference: http://www.igniterealtime.org/projects/openfire/plugins/restapi/readme.html
# Plugin: https://community.igniterealtime.org/external-link.jspa?url=http%3A%2F%2Fwww.igniterealtime.org%2Fprojects%2Fopenfire%2Fplugins.jsp

# includes
require 'rest-client'
require 'json'
require 'yaml'
require 'base64'

# Config (Fill this section out)
VERSION = "0.1"
DEBUG = 1
SERVER_HOST = ""
SERVER_PORT = ""
SECRET_KEY= ""

# Options hash (don't fill this section out)
options = {
  "secret_key" => SECRET_KEY,
  "base_url" => "http://#{SERVER_HOST}:#{SERVER_PORT}/plugins/restapi/v1",
  'user_agent' => "Ruby/Openfire API CLI Enabler #{VERSION}"
}


# Help, abort()
def usage(message)
  print "#{message}\n\n" unless message.empty?
  
  print "openfire_api_enabler.rb \n"
  print "GPLv3 - 2015-12-04 \n"
  print "by Ryan C. Moon (@ryancmoon|ryan@organizedvillainy.com) \n"
  print "\n"
  print "Usage: ./openfire_api_enabler.rb <API VERB> <OPTIONS> \n"
  print "\t**BE CAREFUL USING THIS TOOL, IT WILL NOT BABYSIT YOU** \n"
  print "\tThis tool is for reading text/ascii, it will print nonsense \n"
  print "\tto you let it. \n"
  print "\n"
  print "\tValid Openfire API VERBS: LIST_USERS \n"
  print "\n"
  print "\tOPTIONS: (All <> options are required)\n"
  print "\n\t\tAdmin tools: \n"
  print "\t\tBROADCAST_MESSAGE <message> \n"
  print "\n\t\tUsers: \n"
  print "\t\tLIST_USERS \n"
  print "\t\tGET_USER <username> \n"
  print "\t\tKICK_USER <username> \n"
  print "\t\tADD_USER <username> <name> <user email> <user password> \n"
  print "\t\tUPDATE_USER <username> <name> <user email> <user password> \n"
  print "\t\tUPDATE_PASSWORD <username> <password> \n"
  print "\t\tDELETE_USER <username> \n"
  print "\t\tGET_USER_GROUPS <username> \n"
  print "\t\tADD_TO_GROUP <username> <group name> \n"
  print "\t\tREMOVE_FROM_GROUP <username> <group name> \n"
  print "\t\tLOCKOUT_USER <username> \n"
  print "\t\tUNLOCK_USER <username> \n"
  print "\n\t\tRosters (not functioning): \n"
  print "\t\tGET_USER_ROSTER <username> \n"
  print "\t\tADD_TO_USER_ROSTER <roster owner username> <username to add> \n"
  print "\n\t\tRooms: \n"
  print "\t\tGET_CHATROOMS \n"
  print "\t\tGET_CHATROOM <room name> \n"
  print "\t\tGET_CHATROOM_PARTICIPANTS <room name> \n"
  print "\t\tCREATE_CHATROOM <room name> <description> \n"
  print "\t\tDELETE_CHATROOM <room name> \n"
  print "\t\tUPDATE_CHATROOM <room name> <description> \n"
  print "\n\t\tRoles: \n"
  print "\t\tADD_USER_ROLE <room name or 'global'> <role (admin|owner|member)> <username> \n" 
  print "\t\tREMOVE_USER_ROLE <room name or 'global'> <role (admin|owner|member)> <username> \n" 
  print "\n\t\tGroups: \n"
  print "\t\tGET_GROUPS \n"
  print "\t\tGET_GROUP <group name> \n"
  print "\t\tCREATE_GROUP <group name> <description> \n"
  print "\t\tDELETE_GROUP <group name> \n"
  print "\t\tUPDATE_GROUP <group name> <description> \n"
  print "\n\t\tSessions: \n"
  print "\t\tGET_SESSIONS \n"
  print "\t\tGET_USER_SESSIONS <username> \n"
  print "\n\n"
  
  abort()
end


# Parse command line
def startup_options(options)
  if ARGV[0].nil?
    usage("[!] Error parsing command line options.")
  end
  
  options['api_verb'] = ARGV[0]
  
  case ARGV[0]
  # show all users
  when "LIST_USERS"
    options['url'] = options['base_url'] + "/users"
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  # Get a single user
  when "GET_USER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['username'] = ARGV[1]
    options['url'] = options['base_url'] + "/users/" + options['username']
    
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  # create a new user
  when "ADD_USER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 5
    
    options['url'] = options['base_url'] + "/users"
    options['username'] = ARGV[1]
    options['name'] = ARGV[2]
    options['email'] = ARGV[3]
    options['password'] = ARGV[4]
    options['data'] = { 
       "username" => options['username'],
       "name" => options['name'],
       "email" => options['email'],
       "password" => options['password']
     }
     
    results = post_url(options)
    print "[success] User created. \n"
    
    # create a new user
    when "UPDATE_USER"
      usage("[!] Error parsing command line arguments.") if ARGV.size < 5

      options['username'] = ARGV[1]
      options['name'] = ARGV[2]
      options['email'] = ARGV[3]
      options['password'] = ARGV[4]
      options['data'] = { 
         "username" => options['username'],
         "name" => options['name'],
         "email" => options['email'],
         "password" => options['password']
       }

      options['url'] = options['base_url'] + "/users/" + options['username']
      results = put_url(options)
      print "[success] User updated. \n"
  
  # Update password
  when "UPDATE_PASSWORD"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    
    options['username'] = ARGV[1]
    options['password'] = ARGV[2]
    options['url'] = options['base_url'] + "/users/" + options['username']
    options['data'] = {
      "username" => options['username'],
      "password" => options['password']
    }
  
    results = put_url(options)
    print "[success] User updated. \n"
  
  # delete a user  
  when "DELETE_USER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['username'] = ARGV[1]
    options['url'] = options['base_url'] + "/users/" + options['username']
    
    data = delete_url(options)
    
    print data + "\n"
    
  # get group memberships for a single user
  when "GET_USER_GROUPS"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['username'] = ARGV[1]
    options['url'] = options['base_url'] + "/users/" + options['username'] + '/groups'
    
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  when "ADD_TO_GROUP"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    options['username'] = ARGV[1]
    options['group'] = ARGV[2]
    options['url'] = options['base_url'] + "/users/" + options['username'] + '/groups/' + options['group']
    options['data'] = {}
    
    data = post_url(options)
    
    print "[success] User added to group. \n"
  
  
  when "REMOVE_FROM_GROUP"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    options['username'] = ARGV[1]
    options['group'] = ARGV[2]
    options['url'] = options['base_url'] + "/users/" + options['username'] + '/groups/' + options['group']
    options['data'] = {}
    
    data = delete_url(options)
    
    print data
    
  
  when "LOCKOUT_USER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['username'] = ARGV[1]
    options['url'] = options['base_url'] + "/lockouts/" + options['username'] 
    options['data'] = {}
    
    data = post_url(options)
    
    print "[success] User locked out. \n"
    
  when "UNLOCK_USER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['username'] = ARGV[1]
    options['url'] = options['base_url'] + "/lockouts/" + options['username']
    
    data = delete_url(options)
    
    print "[success] Unlocked user. \n"
    
    
  when "GET_USER_ROSTER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['username'] = ARGV[1]
    options['url'] = options['base_url'] + "/users/" + options['username'] + '/roster'
    
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  
  # This does not work with the current API. Just receives 400- bad request response.  
  when "ADD_TO_USER_ROSTER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    options['username'] = ARGV[1]
    options['roster_add'] = ARGV[2]
    options['url'] = options['base_url'] + "/users/" + options['username'] + '/roster'
    options['data'] = {"RosterItem"=>{"jid"=> options['roster_add']}}
    
    data = post_url(options)
    
    print "[success] Added to user roster. \n"
    
    
  when "GET_CHATROOMS"
    options['url'] = options['base_url'] + "/chatrooms"

    data = get_url(options)

    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  when "GET_CHATROOM"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['chatroom'] = ARGV[1]
    options['url'] = options['base_url'] + "/chatrooms/" + options['chatroom'] 
    
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  when "GET_CHATROOM_PARTICIPANTS"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['chatroom'] = ARGV[1]
    options['url'] = options['base_url'] + "/chatrooms/" + options['chatroom'] + "/participants"
    
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  when "CREATE_CHATROOM"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    options['chatroom'] = ARGV[1]
    options['description'] = ARGV[2]
    options['url'] = options['base_url'] + "/chatrooms"
    options['data'] = {
      "naturalName" => options['chatroom'],
      "roomName" => options['chatroom'],
      "description" => options['description']
      
    }
    
    data = post_url(options)
    
    print "[success] Chatroom created. \n"  
    
  when "DELETE_CHATROOM"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['chatroom'] = ARGV[1]
    options['url'] = options['base_url'] + "/chatrooms/" + options['chatroom']
    
    data = delete_url(options)
    
    print "[success] Deleted chatroom. \n"
    
  when "UPDATE_CHATROOM"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3

    options['chatroom'] = ARGV[1]
    options['description'] = ARGV[2]
    options['url'] = options['base_url'] + "/chatrooms"
    options['data'] = {
      "naturalName" => options['chatroom'],
      "roomName" => options['chatroom'],
      "description" => options['description']
      
    }

    options['url'] = options['base_url'] + "/chatrooms/" + options['chatroom']
    results = put_url(options)
    print "[success] Chatroom updated. \n"
    
    
  when "ADD_USER_ROLE"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 4

    options['chatroom'] = ARGV[1]
    options['role'] = ARGV[2]
    options['username'] = ARGV[3]
    options['url'] = options['base_url'] + "/chatrooms/" + options['chatroom'] + "/" + options['role'] + "s/" + options['username']
    
    data = post_url(options)
    
    print "[success] User role added to chatroom. \n"  
    
  when "DELETE_USER_ROLE"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 4

    options['chatroom'] = ARGV[1]
    options['role'] = ARGV[2]
    options['username'] = ARGV[3]
    options['url'] = options['base_url'] + "/chatrooms/" + options['chatroom'] + "/" + options['role'] + "s/" + options['username']
    
    data = delete_url(options)
    
    print "[success] User role deleted from chatroom. \n"
    
  when "GET_GROUPS"
    options['url'] = options['base_url'] + "/groups"

    data = get_url(options)

    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  when "GET_GROUP"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['group'] = ARGV[1]
    options['url'] = options['base_url'] + "/groups/" + options['group'] 
    
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
  
  when "CREATE_GROUP"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3
    options['group'] = ARGV[1]
    options['description'] = ARGV[2]
    options['url'] = options['base_url'] + "/groups"
    options['data'] = { 
      "name" => options['group'],
      "description" => options['description']
    }
    
    data = post_url(options)
    
    print "[success] Group created. \n"
    
  when "DELETE_GROUP"
      usage("[!] Error parsing command line arguments.") if ARGV.size < 2

      options['group'] = ARGV[1]
      options['url'] = options['base_url'] + "/groups/" + options['group'] 

      data = delete_url(options)

      print "[success] Group deleted. \n"
    
  when "UPDATE_GROUP"  
    usage("[!] Error parsing command line arguments.") if ARGV.size < 3

    options['group'] = ARGV[1]
    options['description'] = ARGV[2]
    options['data'] = {
      "name" => options['group'],
      "description" => options['description']
      
    }

    options['url'] = options['base_url'] + "/groups/" + options['group']
    results = put_url(options)
    print "[success] Group updated. \n"
    
  when "GET_SESSIONS"
    options['url'] = options['base_url'] + "/sessions"

    data = get_url(options)

    print JSON.pretty_generate(parse_yaml(data)) + "\n"
    
  when "GET_SESSION"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['user'] = ARGV[1]
    options['url'] = options['base_url'] + "/sessions/" + options['user'] 
    
    data = get_url(options)
    
    print JSON.pretty_generate(parse_yaml(data)) + "\n"
  
  when "KICK_USER"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2

    options['user'] = ARGV[1]
    options['url'] = options['base_url'] + "/sessions/" + options['user'] 

    data = delete_url(options)

    print "[success] User kicked. \n"
    
  when "BROADCAST_MESSAGE"
    usage("[!] Error parsing command line arguments.") if ARGV.size < 2
    options['message'] = ARGV[1]
    options['url'] = options['base_url'] + "/messages/users"
    options['data'] = { 
      "body" => options['message']
    }
    
    data = post_url(options)
    
    print "[success] Message sent. \n"
    
  else
    usage("[!] An unknown error occurred. Arguments could not be parsed, Arguments Array = #{ARGV}")
  end  
end

# funcitons
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


def get_url(options)
  print "[attempt] GETing #{options['url']}\n" if DEBUG > 0
  
  begin 
    results = RestClient.get options['url'],{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"], "Authorization" => options['secret_key'] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
end

def post_url(options)
  print "[attempt] POSTing #{options['url']}  with data #{options['data']}\n" if DEBUG > 0
  
  begin
    results = RestClient.post options['url'], JSON.dump(options['data']), { :accept => :json, :content_type => :json, :user_agent => options["user_agent"], "Authorization" => options['secret_key'] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 201
    return "[success] Created.\n"
  else
    print "[failure] Openfire REST API returned a strange result: #{results} \n"
    abort
  end
end

def put_url(options)
  print "[attempt] PUTing #{options['url']}  with data #{options['data']}\n" if DEBUG > 0
  
  begin
    results = RestClient.put options['url'], JSON.dump(options['data']), { :accept => :json, :content_type => :json, :user_agent => options["user_agent"], "Authorization" => options['secret_key'] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    return "[success] Updated.\n"
  else
    print "[failure] Openfire REST API returned a strange result: #{results} \n"
    abort
  end
end

def delete_url(options)
  print "[attempt] DELETEing #{options['url']}\n" if DEBUG > 0
  
  begin 
    results = RestClient.delete options['url'],{ :accept => :json, :content_type => :json, :user_agent => options["user_agent"], "Authorization" => options['secret_key'] }
  rescue SocketError => error
    print "[!] Failed. Unknown exception occured with Socket Error when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  rescue Exception => error
    print "[!] Failed. Unknown exception occured when fetching url: #{options['url']}. Exception: #{error} \n"
    abort()
  end
  
  if !results.nil? && results.code == 200
    return "[success] Delete successful.\n"
  else
    print "[failure] Openfire REST API returned a strange result: #{results} \n"
    abort
  end
end




### MAIN #####
startup_options(options)


