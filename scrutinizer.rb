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
g = Group.new

update_counter = 0
ixm.attach_reflex(/^c/) do |packet|
  puts "got packet \"#{packet}\""
  update_counter += 1
  g.update(packet)
  g.plot(update_counter)
end

count = 228
while true
  puts "telling boards I am here [#{count}]"
  ixm << "c#{count} f"
  puts "putting in a new goal"
  ixm << "g 4xxx**+"
  puts "resetting the boards"
  ixm << "r "
  count += 1
  sleep 60
end
