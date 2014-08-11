#!/usr/bin/ruby

require 'rubygems'
require 'stomp'
require 'yaml'

APP_NAME='ruby'
CONF_DIR='/home/ec2-user'

def add_endpoint(gear_id, app_name, ip, port)
  puts "Adding routing endpoint for gear: #{gear_id}-#{app_name}"
  file = File.join(CONF_DIR, "haproxy.cfg")
  if File.exist?(file)
    `echo '    server gear-#{gear_id}-#{app_name} #{ip}:#{port} check fall 2 rise 3 inter 2000 cookie #{gear_id}-#{app_name}' >> #{file}`
  else
    puts "Can't find haproxy config #{CONF_DIR}"
  end
  #{}`nginx -s reload`
end

def remove_endpoint(gear_id, app_name)
  puts "Removing routing endpoint for gear: #{gear_id}-#{app_name}"
  file = File.join(CONF_DIR, "haproxy.cfg")
  if File.exist?(file)
    `sed -i '/gear-#{gear_id}-#{app_name}/d' #{file}`
  else
    puts "Can't find haproxy config #{CONF_DIR}"
  end
  #{}`nginx -s reload`
end

#add_endpoint('53b16890240d8f60f000005e','demo', '54.88.140.1', '57071')
#remove_endpoint('53b16890240d8f60f000005e','demo')
c = Stomp::Client.new("routinginfo", "P@ssw0rd", "172.31.6.115", 61613, true)
c.subscribe('/topic/routinginfo') { 
 | msg |
  puts msg.body
  h = YAML.load(msg.body)
  if h[:app_name] == APP_NAME  
    if h[:action] == :add_public_endpoint and h[:types].include? "web_framework"
       add_endpoint(h[:gear_id], h[:app_name], h[:public_address], h[:public_port])
    elsif h[:action] == :remove_public_endpoint
       remove_endpoint(h[:gear_id], h[:app_name])
    end
  end    
}
c.join