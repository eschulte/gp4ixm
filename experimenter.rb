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
%x{rm /tmp/experimenter/*}

# set up the reflex
ixm.attach_reflex(/^c/) do |packet|
  if packet.match(/^c([\.\d]+) (.*)/)
    print "."; STDOUT.flush;
    $current_file << "#{$1}\t#{$2}\n"
    $current_file.flush
  end
end

count = 44
r_strings.each do |r_s|
  ["9", "xx*", "7xx*+", "987xxx*-+*+"].each_with_index do |goal, index|
    puts "\n\t#{r_s}_#{index}"
    $current_file =
      File.open("/tmp/experimenter/#{r_s.gsub(":",".").gsub(" ","_")}_#{index}.log",
                "w")
    
    # start up the ixm boards running with these settings
    ixm << "c#{count} "
    ixm << "g #{goal}"
    count += 1
    start_time = Time.now
    ixm << r_s
    # let it run for a while
    sleep 120
    
    $current_file.close
  end
end
