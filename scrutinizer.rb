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
require 'tempfile'
require 'libixm/libixm.rb'
require 'board.rb'
require 'group.rb'

# create the ixm object
ixm = LibIXM.new(:sfbprog_path =>   '/home/eschulte/bin/sfbprog', # path for sfbprog or sfbprog.exe
                 :sfbprog_args =>   '',                           # additional arguments
                 :sfbprog_device => '/dev/ttyUSB0',               # device for serial-over-usb
                 :sfbprog_sketch => 'mysketch.hex')               # sketch

g = Group.new

# tell the boards that I am here
ixm << "c4 "

# respond to collector packets
update_counter = 0
ixm.attach_reflex(/^c/) do |packet|
  update_counter += 1
  g.update(packet)
  g.plot(update_counter)
end
