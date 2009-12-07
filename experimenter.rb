#!/usr/bin/env ruby
#
# this can be used to run experiments over a variety of GP settings
# and collect the results an a manner amenable to review/analysis
#
require 'tempfile'
require 'fileutils'
require File.join(File.dirname(__FILE__), "libixm", "libixm.rb")

usage = "Usage: ruby experimenter.rb path/to/results/directory [optional # experiments to skip]"

if ARGV[0] and ARGV[0].match(/help/)
  puts usage
  Process.exit
elsif ARGV[0]
  results_dir = File.expand_path(ARGV[0])
  FileUtils.mkdir_p(results_dir)
else
  puts "you must supply a directory to hold results"
  puts usage
  Process.exit
end

# create the ixm object
puts "initializing ixm connection"
ixm = LibIXM.new(:sfbprog_path =>   '/Users/eschulte/bin/sfbprog',
                 :sfbprog_args =>   '',
                 :sfbprog_device => '/dev/tty.usbserial-FTE5HLY9',
                 :sfbprog_sketch => 'evolve/sketch.hex')

# build up all reset strings
r_strings = ["r"]
[["s", [500]],
 ["m", [10]],
 ["b", [10]],
 ["i", [0]]].each do |key, values|
  new_strings = []
  r_strings = r_strings.each do |r|
    values.each do |val|
      new_strings << "#{r} #{key}:#{val}"
    end
  end
  r_strings = new_strings
end
# possibly pop off the first couple of tests
Integer(ARGV[1]).times{ r_strings.shift }

# start up
puts "running #{(r_strings.size)} experiments"
puts "saving result in #{results_dir}"
puts ""

# set up the reflex
ixm.attach_reflex(/c/) do |packet|
  begin
    if packet.match(/^c([\d-]+\.[\d]+) (\S*)/) # score -- c0.00 f
      print "."; STDOUT.flush;
      $current_file << "#{Time.now - $start_time}\t#{$1}\t#{$2}\n"
      $current_file.flush
      $finished = true if Float($1) == 0
    elsif packet.match(/c([\d\*\-\+\/x]+) (\S*)/) # best -- c44/4x5x5-+* f
      $current_best << "#{Time.now - $start_time}\t#{$1}\t#{$2}\n"
      $current_best.flush
    else
      puts packet
    end
  rescue
    puts "failure!!"
    puts "\t'#{packet}'"
  end
end

ixm.attach_reflex(/k/) do |packet|
  begin
    if packet.match(/^k([\d-]+\/+\.[\d]*\/*)/) # score -- k0.00 f
      print "."; STDOUT.flush;
      $current_file << "k #{Time.now - $start_time}\t#{$1}\n"
      $current_file.flush
      $finished = true if Float($1) == 0
    elsif packet.match(/k([\d\*\-\+\/x]+)/) # best -- c44/4x5x5-+* f
      $current_best << "k #{Time.now - $start_time}\t#{$1}\n"
      $current_best.flush
    else
      puts packet
    end
  rescue
    puts "failure!!"
    puts "\t'#{packet}'"
  end
end

count = 444
r_strings.each do |r_s|
  ["xs55+55+**"].each_with_index do |goal, i|
    5.times do |c|
      print "\n\t#{r_s} run #{c} on #{goal}\n\t"; STDOUT.flush
      $current_file =
        File.open(File.join(results_dir,
                            "#{r_s.gsub(":",".").gsub(" ","_")}_g.#{i}.#{c}.log"),
                  "w")
      $current_best =
        File.open(File.join(results_dir,
                            "#{r_s.gsub(":",".").gsub(" ","_")}_g.#{i}.#{c}.best"),
                  "w")
      $finished = false
      $start_time = Time.now
      
      # start up the ixm boards running with these settings
      ixm << "c#{count} f"
      ixm << "g #{goal}"
      count += 1
       sleep(2)
      ixm << r_s
      # let it run for a while
      sleep_counter = 0
      while((not $finished) and (sleep_counter < 600))
        sleep 1
        sleep_counter += 1
      end
      
      $current_file.close
      $current_best.close
    end
  end
  # break
end
