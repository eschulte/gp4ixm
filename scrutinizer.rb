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
# require 'libixm'

# # create the ixm object
# ixm = LibIXM.new(:sfbprog_path =>   '/usr/bin/sfbprog', # path for sfbprog or sfbprog.exe
#                  :sfbprog_args =>   '',                 # additional arguments
#                  :sfbprog_device => '/dev/ttyUSB0',     # device for serial-over-usb
#                  :sfbprog_sketch => 'mysketch.hex')     # sketch
#
# # respond to collector packets
# ixm.attach_reflex( /^c/ ) do |packet|
#
# end

# a Group represents a connected set of boards
class Group
  attr_accessor :count, :boards

  # create a new empty group
  def initialize() self.count = 0; self.boards = [] end

  # fill in empty spots between boards w/0s
  def fill_boards
    # find the corners of the square bounding the points
    xmin = 0; xmax = 0; ymin = 0; ymax = 0
    by_cords = boards.map{ |b| b.x_y }
    by_cords.each do |x, y|
      xmin = x if x < xmin
      xmax = x if x > xmax
      ymin = y if y < ymin
      ymax = y if y > ymax
    end
    # fill in every point in the square
    (xmin..xmax).each{ |x|
      (ymin..ymax).each{ |y|
        self.boards << Board.new("", 0, [x, y]) unless by_cords.include?([x, y]) }  }
    self.boards
  end

  # send an initialization message through the boards letting them
  # know that there is a data collector and where to send their
  # packets.
  def touch
    count += 1
    # use libixm to send this message to the boards
    "c#{count} \n"
  end

  # update this group with a packet
  def update(packet)
    # find the board by the location string
    # change the boards value
  end

  # output data in a manner ingestible by gnuplot
  def data()
    boards.sort_by{ |b| b.x_y[0] }.sort_by{ |b| b.x_y[1] }.map{ |b| b.data_line }.join("\n")
  end

  # dump my data to a temporary file
  def data_file
    # create a temp file
    t = Tempfile.new("scrutinizer-gnuplot")
    t << self.data
    t.flush
    t.path
  end

  # generate a gnuplot script using techniques from
  # http://t16web.lanl.gov/Kawano/gnuplot/plot3d2-e.html
  def plot_script
    ["set term png",
     "set output \"/home/eschulte/result.png\"",
     "set dgrid3d 30, 30",
     "set hidden3d",
     "splot \"#{self.data_file}\" with lines title 'fitness' "].join("\n")
  end
  
  def plot
    g = Tempfile.new("scrutinizer-gnuplot-plot")
    g << self.plot_script
    g.flush
    %x{gnuplot #{g.path}}
  end
end

# An ixm board with location and value
class Board
  attr_accessor :location, :value, :cords
  def initialize(location = "", value = 0, cords = nil)
    self.location = location
    self.value = value
    self.cords = cords
  end

  # convert the lrfrfl location strings to grid coordinates
  def x_y
    self.cords or
      (
       # dir n s e w s.t. n=0 e=1 s=2 w=4
       dir = 0;
       # x and y coordinates
       y = 0
       x = 0
       location.split(//).each do |l|
         case l            # adjust bearing in n s e w
         when "f"
         when "r" then dir = (dir + 1).modulo(4)
         when "l" then dir = (dir - 1).modulo(4)
         end
         case dir           # take one step and update position in (x, y) coordinates
         when 0 then y += 1 # north
         when 1 then x += 1 # east
         when 2 then y -= 1 # south
         when 3 then x -= 1 # west
         end
       end
       [x, y]
       )
  end

  # return a line suitable for inclusion into a data file for gnuplot
  def data_line
    (self.x_y + [value, "\n"]).map{ |v| v.to_s }.join("\t")
  end
  # not to be used (doesn't quite meet gnuplot's baroque 3d requirements)
  def data_chunk
    coords = self.x_y
    col = coords[0]
    row = coords[1]
    val = self.value
    [
     [col - 1, row - 0.5, val].map{ |v| v.to_s }.join("\t"),
     [col - 1, row + 0.5, val].map{ |v| v.to_s }.join("\t"),
     [col, row - 0.5, val].map{ |v| v.to_s }.join("\t"),
     [col, row + 0.5, val].map{ |v| v.to_s }.join("\t")].join("\n") + "\n"
  end
end
