class DungeonPath

    N = [0, -1]
    W = [-1, 0]
    S = [0, 1]
    E = [1, 0]

  def initialize(length, weights = [1, 1, 1, 1])
    @weight_north = weights[0]
    @weight_west = weights[2]
    @weight_east = weights[1]
    @weight_south = weights[3]

    @nodes = []
  end

  def generate
    node = DungeonPathNode.new
    @nodes.push(node)
    available_dirs = []
    for i in 0...@weight_north do available_dirs.push(N) end
    for i in 0...@weight_west do available_dirs.push(W) end
    for i in 0...@weight_east do available_dirs.push(E) end
    if node.y > 0
      for i in 0...@weight_south do available_dirs.push(S) end
    end
    move = available_dirs[rand(available_dirs.length)]
    new_x = x + move[0]
    new_y = y + move[1]
    node[move] = DungeonPathNode.new
    node[move][DungeonPathNode::invert(move)] = node
    node = node[move]

  end



  class DungeonPathNode


    NORTH = 0
    WEST = 1
    SOUTH = 2
    EAST = 3

    @north = nil
    @west = nil
    @east = nil
    @south = nil

    @x = 0
    @y = 0

    def self.invert(dir)
      (dir + 2) % 4
    end


    def [](i)
      case i
      when NORTH then @north
      when WEST then @west
      when EAST then @east
      when SOUTH then @south
      end
    end

    def []=(i, val)
      case i
      when NORTH then @north = v
      when WEST then @west = v
      when EAST then @east = v
      when SOUTH then @south = v
      end
    end

    attr_accessor :north, :east, :west, :south, :x, :y
  end
end

class Path2D
  @begin_x = 0
  @begin_y = 0
  @end_x = 0
  @end_y = 0
  @data = []

  def width() 
    zero_comp = begin_x.negative? && end_x.positive? ? 1 else 0
    @end_x - begin_x + zero_comp
  end
  def height()
    zero_comp = begin_y.negative? && end_y.positive? ? 1 else 0
    @end_y - begin_y + zero_comp
  end


  def set(coord, val)
   
  end

  def ensure_space(coord)
   while coord.y < @begin_y
      for i in 0...data.length
        data[i].unshift(nil)
      end
      @begin_y -= 1
    end
    while coord.y > @end_y
      for i in 0...data.length
        data[i].push(nil)
      end
      @end_y += 1
    end
    while coord.x < @begin_x
      data.unshift(Array(height))
      @begin_x -= 1
    end
    while coord.x > @end_x
      data.push(Array(height))
      @end_x += 1
    end
  end

  def has?(x,y)

  end

  class Coord
    N = Coord.new(0, -1)
    W = Coord.new(-1, 0)
    S = Coord.new(0, 1)
    E = Coord.new(1, 0)

    def initialize(x, y)
      $x = x
      $y = y
    end

    def +(other)
      Coord(@x+other.x, @y+other.y)
    end
  end

end