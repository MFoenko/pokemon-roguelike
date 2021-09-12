class DungeonRoomPositions
  def initialize(length, weights = [1, 1, 1, 1])
    @weight_north = weights[0]
    @weight_west = weights[2]
    @weight_east = weights[1]
    @weight_south = weights[3]

    @length = length

    @grid = FlexGrid.new
    @path = []
    @moves = []
  end

  def generate
    coords = FlexGrid::Coord::START
    @grid[coords] = 0
    @path.push(coords)

    room_number = 1

    (@length-1).times do |i|
      available_dirs = []
      @weight_north.times { available_dirs.push(FlexGrid::Coord::N) } if @grid[coords + FlexGrid::Coord::N].nil?
      @weight_west.times { available_dirs.push(FlexGrid::Coord::W) } if @grid[coords + FlexGrid::Coord::W].nil?
      @weight_east.times { available_dirs.push(FlexGrid::Coord::E) } if @grid[coords + FlexGrid::Coord::E].nil?
      if (coords + FlexGrid::Coord::S).y.positive? && @grid[coords + FlexGrid::Coord::S].nil? && i < @length - 2
        @weight_south.times { available_dirs.push(FlexGrid::Coord::S) }
      end

      break if available_dirs.empty?

      move = available_dirs[rand(available_dirs.length)]
      coords += move
      @grid[coords] = room_number
      @path.push(coords)
      @moves.push(move)
      room_number += 1
    end
  end

  def normalize
    for coord in @path
      coord.x += -@grid.begin_x
      coord.y += -@grid.begin_y
    end
    @grid.normalize
  end

  def inspect
    @grid.inspect
  end

  attr_accessor :grid, :path, :moves, :length
end

class FlexGrid
  def initialize
    @begin_x = 0
    @begin_y = 0
    @end_x = 0
    @end_y = 0
    @data = [[nil]]
  end

  attr_accessor :begin_x, :begin_y, :end_x, :end_y

  def width
    zero_comp = @begin_x <= 0 || @end_x >= 0 ? 1 : 0
    @end_x - @begin_x + zero_comp
  end

  def height
    zero_comp = @begin_y <= 0 || @end_y >= 0 ? 1 : 0
    @end_y - @begin_y + zero_comp
  end

  def items_in_col(col)
    @data[col - @begin_x].filter { |v| !v.nil? }
  end

  def items_in_row(row)
    elements = []
    for col in @data
      element = col[row]
      elements.push(element) unless element.nil?
    end
    elements
  end

  def []=(coord, val)
    ensure_space(coord)
    @data[coord.x - @begin_x][coord.y - @begin_y] = val
  end

  def empty?(offset_x, offset_y, width = 1, height = 1)
    for x in 0..width
      for y in 0..height
        return false if !self[Coord.new(offset_x + x, offset_y + y)].nil?
      end
    end
    return true
  end

  def draw_rectangle(offset_x, offset_y, width, height, table, table_x, table_y)
    # ensure space for the entire rectangle
    ensure_space(Coord.new(offset_x, offset_y))
    ensure_space(Coord.new(offset_x + width, offset_y + height))
    # echoln "x=#{table_x} y=#{table_y}, width=#{width} height=#{height}"

    for i in 0...width
      for j in 0...height
        x = table_x + i
        y = table_y + j
        point = Coord.new(offset_x + i, offset_y + j)
        self[point] = [0, 0, 0] if self[point].nil?
        self[point][0] = table[x, y, 0] if table[x,y,0] != 0
        self[point][1] = table[x, y, 1] if table[x,y,1] != 0
        self[point][2] = table[x, y, 2] if table[x,y,2] != 0
      end
    end
  end

  def ensure_space(coord)
    while coord.y < @begin_y
      for i in 0...@data.length
        @data[i].unshift(nil)
      end
      @begin_y -= 1
    end
    while coord.y > @end_y
      for i in 0...@data.length
        @data[i].push(nil)
      end
      @end_y += 1
    end
    while coord.x < @begin_x
      @data.unshift(Array.new(height))
      @begin_x -= 1
    end
    while coord.x > @end_x
      @data.push(Array.new(height))
      @end_x += 1
    end
  end

  def normalize
    @end_x += -@begin_x
    @end_y += -@begin_y
    @begin_x = 0
    @begin_y = 0
  end

  def [](coord)
    return nil if !exists?(coord)
    col = @data[coord.x - @begin_x]
    return nil if col.nil?
    col[coord.y - @begin_y]
  end

  def exists?(coord)
    !(coord.nil? || coord.x < @begin_x || coord.y < @begin_y || coord.x > @end_x || coord.y > @end_y)
  end

  def inspect
    string = ''
    # echoln "w=#{width} h=#{height}"
    for y in 0...height
      for x in 0...width
        # echoln "x=#{x} y=#{y}"
        cell = @data[x][y]
        string += "#{cell.nil? ? ' ' : cell}".fix(4)
      end
      string += "\n\r"
    end
    string
  end

  class Coord
    def initialize(x, y)
      @x = x
      @y = y
    end

    START = Coord.new(0, 0)
    N = Coord.new(0, -1)
    W = Coord.new(-1, 0)
    S = Coord.new(0, 1)
    E = Coord.new(1, 0)

    def +(other)
      Coord.new(@x + other.x, @y + other.y)
    end

    def inspect
      "#{x},#{y}"
    end

    attr_accessor :x, :y
  end
end

class String
  def fix(size, padstr=' ')
    self[0...size].rjust(size, padstr) #or ljust
  end
end