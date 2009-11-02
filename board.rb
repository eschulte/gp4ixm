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

  def x() self.x_y[0] end

  def y() self.x_y[1] end

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
