# a Group represents a connected set of boards
#
#  to exercise the graphing library...
#
#     g = Group.new
#     g.boards = [["frffff", 7], ["frfrfff", 4], ["lfffff", 3], ["f", 9]].map{|l, v| Board.new(l, v) }
#     g.fill_boards.size
#     g.plot
#     
require 'tempfile'
require 'board.rb'

class Group
  attr_accessor :count, :boards, :base, :maxvalue

  # create a new empty group
  def initialize()
    self.count = 0
    self.boards = []
    self.maxvalue = 0
    # base directory/path where images are stored
    self.base = "/tmp/scrutinizer/group"
  end

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
    xmin -= 1
    xmax += 1
    ymin -= 1
    ymax += 1
    # fill in every point in the square
    (xmin..xmax).each{ |x|
      (ymin..ymax).each{ |y|
        self.boards << Board.new("", 0, [x, y]) unless by_cords.include?([x, y]) }  }
    self.boards
  end
  
  def rows
    # find the corners of the square bounding the points
    xmin = 0; xmax = 0
    by_cords = boards.map{ |b| b.x_y }
    by_cords.each{ |x, y| xmin = x if x < xmin; xmax = x if x > xmax }
    # fill in every point in the square
    (xmin..xmax)
  end

  def cols
    # find the corners of the square bounding the points
    ymin = 0; ymax = 0
    by_cords = boards.map{ |b| b.x_y }
    by_cords.each{ |x, y| ymin = y if y < ymin; ymax = y if y > ymax }
    # fill in every point in the square
    (ymin..ymax)
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
    if packet.match(/^c([\.\d]+) (.+)/)
      new_b = Board.new($2, Float($1))
      remaining = self.boards.reject{ |b| b.x_y == new_b.x_y }
      self.boards = remaining << new_b
      self.fill_boards
    end
  end

  # fancier gnuplot graphs
  #
  # (gnuplot-row (col row value)
  # 	    (setf col (+ 1 col)) (setf row (+ 1 row))
  # 	    (format "%f  %f  %f\n%f  %f  %f\n"
  # 		    col (- row 0.5) value ;; lower edge
  # 		    col (+ row 0.5) value))) ;; upper edge
  def gnuplot_row(col, row, value)
    col += 1; row += 1
    "#{col} #{row - 0.5} #{value}\n#{col} #{row + 0.5} #{value}\n"
  end

  # output data in a manner ingestible by gnuplot
  #
  # (dotimes (col num-cols)
  #    (dotimes (row num-rows)
  #      (setf back-edge
  #	    (concat back-edge
  #		    (gnuplot-row (- col 1) row (string-to-number
  #						(nth col (nth row table))))))
  #      (setf front-edge
  #	    (concat front-edge
  #		    (gnuplot-row col row (string-to-number
  #					  (nth col (nth row table)))))))
  #    ;; only insert once per row
  #    (insert back-edge) (insert "\n") ;; back edge
  #    (insert front-edge) (insert "\n") ;; front edge
  #    (setf back-edge "") (setf front-edge ""))
  def data()
    self.cols.map do |col|
      back_edge = ""; front_edge = ""
      self.boards.select{|b| b.y == col}.sort_by{ |b| b.x }.each do |b|
        self.maxvalue = b.value if b.value > self.maxvalue
        back_edge += gnuplot_row((b.y - 1), b.x, b.value)
        front_edge += gnuplot_row(b.y, b.x, b.value)
      end
      back_edge + "\n" + front_edge
    end.join("\n")
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
  def plot_script(counter = false)
    ["set term png",
     (if counter
        "set output \"#{base}.#{counter}.png\""
      else
        "set output \"#{base}.png\""
      end),
     "set zrange [0:#{self.maxvalue}]",
     "set pm3d",
     "splot \"#{self.data_file}\" with pm3d title 'fitness' "].join("\n")
  end

  def plot(counter = false)
    g = Tempfile.new("scrutinizer-gnuplot-plot")
    g << self.plot_script(counter)
    g.flush
    %x{gnuplot #{g.path} 2> /dev/null}
    g.path
  end

  # create an animated gif of the visualizations (require imagemagick)
  def animate() %x{convert -delay 20 -loop 1 #{base}*.png #{base}.gif} end

end
