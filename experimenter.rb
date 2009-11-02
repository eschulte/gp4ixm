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
puts "starting #{(r_strings.size) * 5 * 4} runs"
%x{mkdir -p /tmp/experimenter}
%x{rm /tmp/experimenter/*}

# set up the reflex
ixm.attach_reflex(/^c/) do |packet|
  if packet.match(/^c([\.\d]+) (.*)/)
    print "."; STDOUT.flush;
    $current_file << "#{Time.now - $start_time}\t#{$1}\t#{$2}\n"
    $current_file.flush
    $finished = true if Float($1) < 1
  end
end

count = 4
r_strings.each do |r_s|
  ["xx*", "xxx**", "7xx*+", "987xxx*-+*+"].each_with_index do |goal, i|
    5.times do |c|
      print "\n\t#{r_s} run #{c} on #{goal}\n\t"; STDOUT.flush
      $current_file =
        File.open("/tmp/experimenter/"+
                  "#{r_s.gsub(":",".").gsub(" ","_")}_g.#{i}.#{c}.log", "w")
      $finished = false
      $start_time = Time.now
      
      # start up the ixm boards running with these settings
      ixm << "c#{count} "
      ixm << "g #{goal}"
      count += 1
      ixm << r_s
      # let it run for a while
      sleep_counter = 0
      while((not $finished) and (sleep_counter < 30))
        sleep 10
      end
      
      $current_file.close
    end
  end
end
