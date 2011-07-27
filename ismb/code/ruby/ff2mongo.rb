#!/usr/bin/ruby

require "rubygems"
require "mongo"
require "json/pure"
require "open-uri"

# db config
db   = Mongo::Connection.new.db('friendfeed')
feed = ARGV[0] or abort "Usage: ff2mongo <feed>"
col  = db.collection(feed.gsub("/", "-"))

# fetch json
0.step(13900, 100) {|n|
  f = open("http://friendfeed-api.com/v2/feed/#{feed}?start=#{n}&num=100").read
  j = JSON.parse(f)
  break if j['entries'].count == 0
  j['entries'].each do |entry|
      entry[:_id] = entry['id']
      entry.delete('id')
      entry[:feed_id]   = j['id']
      entry[:feed_name] = j['name']
      entry[:feed_description] = j['description']
      entry[:feed_type] = j['type']
      col.save(entry)
  end
  puts "Processed entries #{n} - #{n + 99}", "#{feed} contains #{col.count} documents."
  sleep(3)
}

puts "No more entries to process. #{feed} contains #{col.count} documents."
