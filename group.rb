# a Group represents a connected set of boards
require 'board.rb'

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
