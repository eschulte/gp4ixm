#!/usr/bin/env ruby
#
# this can be used to run experiments over a variety of GP settings
# and collect the results an a manner amenable to review/analysis
#
require 'tempfile'
require 'libixm/libixm.rb'

# create the ixm object
puts "initializing ixm connection"
ixm = LibIXM.new(:sfbprog_path =>   '/Users/eschulte/bin/sfbprog', # path for sfbprog or sfbprog.exe
                 :sfbprog_args =>   '',                            # additional arguments
                 :sfbprog_device => '/dev/tty.usbserial-FTE5HPVE', # device for serial-over-usb
                 :sfbprog_sketch => 'single-evolve/sketch.hex')    # sketch

puts "running some experiments..."

r_strings = ["r"]

[["m", [0, 10]],
 ["b", [0, 10]],
 ["i", [0, 10]],
 ["t", [100, 4, 1]]].each do |key, values|
  new_strings = []
  r_strings = r_strings.each do |r|
    values.each do |val|
      new_strings << "#{r} #{key}:#{val}"
    end
  end
  r_strings = new_strings
end
r_strings.shift
r_strings.shift
r_strings.shift

# start up 
puts "starting #{r_strings.size} runs"
%x{mkdir -p /tmp/experimenter}

count = 44
r_strings.each do |r_s|
  puts "\t#{r_s}"
  f = File.open("/tmp/experimenter/#{r_s.gsub(":",".").gsub(" ","_")}.log","w")

  # start up the ixm boards running with these settings
  begin
    ixm << "c#{count} "
    ixm << "g xxx**"
    count += 1
    start_time = Time.now
    ixm << r_s
    ixm.attach_reflex(/^c/) do |packet|
      if packet.match(/^c([\.\d]+) (.+)/)
        puts "\t\t#{(Time.now - start_time).round}\t#{$1}\t#{$2}"
        f << "#{(Time.now - start_time).round}\t#{$1}\t#{$2}\n"
        f.flush
        if Integer($1) == 0
          raise "finished"
        end
      end
    end
    5.times do
      sleep 30
      puts "\t30..."
    end
  rescue
    puts "\tcompleted in #{(Time.now - start_time).round} seconds"
  end
end
