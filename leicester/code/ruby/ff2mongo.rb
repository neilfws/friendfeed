#!/usr/bin/ruby

require "rubygems"
require "mongo"
require "json/pure"
require "open-uri"

# db config
db   = Mongo::Connection.new.db('friendfeed')
feed = ARGV[0] || "the-life-scientists"
col  = db.collection(ARGV[1]) || db.collection('lifesci')

# fetch json
0.step(9900, 100) {|n|
  f = open("http://friendfeed-api.com/v2/feed/#{feed}?start=#{n}&num=100").read
  j = JSON.parse(f)
  break if j['entries'].count == 0
  j['entries'].each do |entry|
    if col.find({:_id => entry['id']}).count == 0
      entry[:_id] = entry['id']
      entry.delete('id')
      col.save(entry)
    end
  end
  puts "Processed entries #{n} - #{n + 99}", "Database contains #{col.count} documents."
}

puts "No more entries to process. Database contains #{col.count} documents."
