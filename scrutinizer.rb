#!/usr/bin/env ruby
#
# this is the central scrutinizer which handles data collection from
# ixm boards running collector/sketch.pde
#
#
# use the following to run a Group through it's paces
#
#     g = Group.new
#     g.boards = [["frffff", 7], ["frfrfff", 4], ["lfffff", 3], ["f", 9]].map{|l, v| Board.new(l, v) }
#     g.fill_boards.size
#     g.plot
#     
require 'libixm/libixm.rb'
require 'board.rb'
require 'group.rb'

# create the ixm object
puts "initializing ixm connection"
ixm = LibIXM.new(:sfbprog_path =>   '/Users/eschulte/bin/sfbprog', # path for sfbprog or sfbprog.exe
                 :sfbprog_args =>   '',                            # additional arguments
                 :sfbprog_device => '/dev/tty.usbserial-FTE5HPVE', # device for serial-over-usb
                 :sfbprog_sketch => 'single-evolve/sketch.hex')    # sketch

puts "creating board group"
puts "putting in a new goal"
ixm << "g 987xxx*-+*+"
sleep(2) # let the goal get a head start
puts "resetting the boards"
ixm << "r "
g = Group.new("/Users/eschulte/Desktop/gp-results")

update_counter = 0
ixm.attach_reflex(/^c/) do |packet|
  if packet.match(/^c([\.\d]+) (.+)/)
    puts "\t#{$2}\t#{$1}"
  end
  update_counter += 1
  g.update(packet)
end

count = 2
while true
  if count%10 == 0
    puts "telling boards I am here [#{count}]"
    ixm << "c#{count} f"
    # reset the max value
    g.maxvalue = 0
  end
  count += 1
  g.plot(update_counter)
  sleep 1
end
