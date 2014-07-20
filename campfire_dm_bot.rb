require 'rubygems'
require 'yaml'
require 'tinder'
require 'twitter'

class Ping
  def initialize
    @config = YAML.load_file('config.yml')
    @campfire = Tinder::Campfire.new @config['campfire_domain'], :username => @config['campfire_username'], :password => @config['campfire_password']
    @room = @campfire.find_room_by_id(@config['campfire_room'])
    @twitter_username_mapping = @config['twitter_mapping']
    @client = Twitter::Client.new(
      :consumer_key => @config["api_key"],
      :consumer_secret => @config["api_secret"],
      :oauth_token => @config["access_token"],
      :oauth_token_secret => @config["access_token_secret"])
  end    
  
  def start_listening
    @room.listen do |m|
      parse_message(m)
    end
  end   

  def parse_message(message)
    if (message[:type] == 'TextMessage' || message[:type] == "PasteMessage")
      body = message[:body]
      if body.downcase.start_with?('ping')     
        message_array = body.downcase.split
        if message_array.length < 2
          @room.speak 'Name missing. Usage instructions: Ping <Name>. Example: Ping Murat'
          return
        end    
        username = @twitter_username_mapping[message_array[1]]
        if !username    
          @room.speak 'Name to Twitter username mapping not found. Please get in touch with Swapnil to add this entry.'
          return
        end
        dm(username, message[:user][:name])      
      end   
    end
  end  

  def dm(username, sender)
    begin
      puts sender
      response = @client.direct_message_create(username, sender + ' pinged you in the ' + @room.name + " campfire room!") 
    rescue Exception => e 
      puts e.message
      @room.speak 'Oops! Seems like Twitter API is down.'      
    else
      @room.speak username + "has been pinged!"  
    end
  end  
end

Ping.new.start_listening