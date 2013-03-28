require 'pry'
require 'net/http'
require 'uri'

f = File.open("cmcc.info", "r")

action = f.gets.chomp

params = {}

while not f.eof?
  name  = f.gets.chomp
  value = f.gets.chomp
  empty = f.gets

  params[name] = value
end


post_res = Net::HTTP.post_form(URI.parse(action), params)
puts "Done"