#!/usr/bin/ruby

require "rubygems"
require "json/pure"
require "open-uri"
require "optparse"
require "date"

# define start/end dates
$dstart = Date.new(2010,1,25)
$dend   = Date.new(2010,3,26)

def define_options
  options = {}
  optparse = OptionParser.new do |opts|
    opts.banner = "Usage: ffuserdata.rb [-u,--user] username [-r,--remote] remotekey [-f,--feed] feed [-t,--type] type"
    # option user
    options[:user] = nil
    opts.on( '-u', '--user [USER]', 'Your user name') do |u|
      options[:user] = u
    end
    # option remotekey
    options[:remote] = nil
    opts.on( '-r', '--remote [REMOTE]', 'Your remote key') do |r|
      options[:remote] = r
    end
    # option feed
    options[:feed] = nil
    opts.on( '-f', '--feed [FEED]', 'Name of feed to retrieve') do |f|
      options[:feed] = f
    end
    # option type
    options[:type] = nil
    opts.on( '-t', '--type [TYPE]', [:entries, :likes, :comments, :subscriptions, :subscribers], 'Type of data to retrieve (entries, likes, comments, subscriptions, subscribers)') do |f|
      options[:type] = f
    end
    # option help
    opts.on('-h', '--help', 'Display this help') do
      puts opts
      exit
    end
  end
  return [optparse,options]
end

def parse_options(opts)
  begin
    opts[0].parse!
    mandatory = [:user, :remote, :feed, :type]
    missing = mandatory.select{ |param| opts[1][param].nil? }
    if not missing.empty?
      puts "Missing options: #{missing.join(', ')}"
      puts opts[0]
      exit
    end
  rescue OptionParser::InvalidOption, OptionParser::InvalidArgument, OptionParser::MissingArgument
    puts $!.to_s
    puts opts[0]
    exit
  end
  return opts[1]
end

def fetch_entries(options,url)
  entries = []
  body    = ""
  puts "Fetching #{options[:type]} for #{options[:feed]}..."
  entries << ["user", "entry", "service", "date", "time", "comments", "likes"]
  0.step(9900, 100) do |n|
    file = open("#{url}/feed/#{options[:feed]}?start=#{n}&num=100", :http_basic_authentication => [options[:user],options[:remote]]).read
    json = JSON.parse(file)
    break if json['entries'].count == 0
    json['entries'].each do |entry|
      body += "#{entry['body']}\n"
      service  = entry.has_key?('via') ? entry['via']['name'] : "unknown"
      comments = entry.has_key?('comments') ? entry['comments'].length : 0
      likes    = entry.has_key?('likes') ? entry['likes'].length : 0
      date = entry['date'] =~/(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})Z/ ? "#{$1},#{$2}" : entry['date']
      if Date.parse(entry['date']) >= $dstart && Date.parse(entry['date']) <= $dend
        entries << [json['id'],entry['id'],service,date,comments,likes]
      end
    end
    puts "Processed #{options[:type]} #{n} - #{n + 99}..."
  end
  puts "No more #{options[:type]} to process."
  write_to_file(entries,"#{options[:feed]}.#{options[:type]}.csv")
  File.open("#{options[:feed]}.#{options[:type]}.body.txt", "w") do |f|
    f.puts body
  end
end

def fetch_comments_or_likes(options,url)
  feedback = []
  type = options[:type].to_s
  puts "Fetching #{options[:type]} for #{options[:feed]}..."
  case type
    when "comments"
    feedback << ["author", "comment_by", "entry", "comment", "date", "time"]
    when "likes"
    feedback << ["author", "liked_by", "entry", "date", "time"]
  end
  0.step(9900, 100) do |n|
    file = open("#{url}/feed/#{options[:feed]}/#{type}?start=#{n}&num=100", :http_basic_authentication => [options[:user],options[:remote]]).read
    json = JSON.parse(file)
    break if json['entries'].count == 0
    json['entries'].each do |entry|
      case type
        when "comments"
        entry['comments'].each do |comment|
          if comment['from']['id'] == options[:feed]
            ec = comment['id'] =~/^e\/(.*?)\/c\/(.*?)$/ ? "#{$1},#{$2}" : comment['id']
            date = comment['date'] =~/(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})Z/ ? "#{$1},#{$2}" : comment['date']
            if Date.parse(comment['date']) >= $dstart && Date.parse(comment['date']) <= $dend
              feedback << [entry['from']['id'],comment['from']['id'],ec,date]
            end
          end
        end
        when "likes"
        entry['likes'].each do |like|
          if like['from']['id'] == options[:feed]
            date = like['date'] =~/(\d{4}-\d{2}-\d{2})T(\d{2}:\d{2}:\d{2})Z/ ? "#{$1},#{$2}" : like['date']
            if Date.parse(like['date']) >= $dstart && Date.parse(like['date']) <= $dend
              feedback << [entry['from']['id'],like['from']['id'],entry['id'],date]
            end
          end
        end
      end
    end
    puts "Processed #{options[:type]} #{n} - #{n + 99}..."
  end
  puts "No more #{options[:type]} to process."
  write_to_file(feedback,"#{options[:feed]}.#{options[:type]}.csv")
end


def fetch_info(options,url)
  info = []
  puts "Fetching #{options[:type]} for #{options[:feed]}..."
  file = open("#{url}/feedinfo/#{options[:feed]}", :http_basic_authentication => [options[:user],options[:remote]]).read
  json = JSON.parse(file)
  case options[:type].to_s
    when "subscriptions"
    info << ["user", "subscription", "type"]
    json['subscriptions'].each do |sub|
      info << [json['id'], sub['id'], sub['type']]
    end
    when "subscribers"
    info << ["subscriber", "user"]
    json['subscribers'].each do |sub|
      info << [sub['id'], json['id']]
    end
  end
  write_to_file(info,"#{json['id']}.#{options[:type]}.csv")
end

def write_to_file(data,filename)
  File.open(filename, "w") do |f|
    data.each do |record|
      f.puts record.join(",")
    end
  end
  puts "Wrote #{filename}."
end

# check command line options
options = define_options
options = parse_options(options)
url     = "http://friendfeed-api.com/v2"

# let's go!
case options[:type].to_s
  when "entries"
  fetch_entries(options,url)
  when "comments", "likes"
  fetch_comments_or_likes(options,url)
  when "subscriptions", "subscribers"
  fetch_info(options,url)
end
