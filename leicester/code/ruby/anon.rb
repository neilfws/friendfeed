#!/usr/bin/ruby

file = ARGV[0]
m = 0
f = 0

File.read(file).each do |line|
  line.chomp!
  user = line.split(",")
  case user[1]
    when "M"
      m += 1
      user.push("M#{sprintf('%.2d', m)}")
    when "F"
      f += 1
      user.push("F#{sprintf('%.2d', f)}")
  end
  puts user.join(",")
end
