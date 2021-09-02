class MazeConstants
  NORTH = 0b0001
  EAST = 0b0100
  WEST = 0b0010
  SOUTH = 0b1000

  def self.invert(direction)
    case direction
    when NORTH then SOUTH
    when EAST then WEST
    when WEST then EAST
    when SOUTH then NORTH
    end
  end

end

class SpelunkyMaze

  X_WEIGHT = 2
  Y_WEIGHT = 2

  def initialize(width, height, startX = rand(width), startY = height-1)
    @width = width
    @height = height
    @grid = Array.new(@width) { Array.new(@height) { SpelunkyMazeCell.new } }
    echoln @grid

    @start_x = startX
    @start_y = startY
  end

  def generate
    return if @width <= 0 || @height <= 0

    # start by picking a random tile at the bottom to be the entrance

    x = @start_x
    y = @start_y

    explored = []
    # while we're not at the top of the maze
    while y > 0
      explored.push(@grid[x][y])

      # determine the directions we can move in
      move_pool = []
      if y > 0 && !explored.include?(@grid[x][y - 1])
        for i in 0...Y_WEIGHT
          move_pool.push(MazeConstants::NORTH)
        end
      end
      if x > 0 && !explored.include?(@grid[x - 1][y])
        for i in 0...X_WEIGHT
          move_pool.push(MazeConstants::WEST)
        end
      end

      if y < @height - 1 && !explored.include?(@grid[x][y + 1])
        for i in 0...Y_WEIGHT
          move_pool.push(MazeConstants::SOUTH)
        end
      end
      if x < @width - 1 && !explored.include?(@grid[x + 1][y])
        for i in 0...X_WEIGHT
          move_pool.push(MazeConstants::EAST)
        end
      end

      # if out of directions to move, we've fucked up, exit
      # TODO update logic so that this doesn't happen
      break if move_pool.length.zero?

      # pick a random direction
      move = move_pool[rand(move_pool.length)]

      echoln "x=#{x} y=#{y} move_pool=#{move_pool} move=#{move}"
      # add an opening to the current cell in the direction we're moving
      @grid[x][y].addBitmask(move)
      # move in that direction
      case move
      when MazeConstants::NORTH then y -= 1
      when MazeConstants::WEST then x -= 1
      when MazeConstants::SOUTH then y += 1
      when MazeConstants::EAST then x += 1
      end
      # add an opening to the previous cell in the new cell
      inverse_move = MazeConstants::invert(move)
      @grid[x][y].addBitmask(inverse_move)
    end

    @grid[x][y].addBitmask(MazeConstants::NORTH) if y == @height - 1
    @grid[@start_x][@start_y].addBitmask(MazeConstants::SOUTH)
  end

  echoln @grid

  def [](x, y)
    @grid[x][y]
  end

  attr_accessor :start_x
  attr_accessor :start_y
end

class SpelunkyMazeCell
  @north = 0
  @east = 0
  @west = 0
  @south = 0
  @is_on_path = false

  def bitmask
    bits = 0
    bits |= MazeConstants::NORTH if @north == 1
    bits |= MazeConstants::WEST if @west == 1
    bits |= MazeConstants::EAST if @east == 1
    bits |= MazeConstants::SOUTH if @south == 1
    bits
  end

  def setBitmask(bitmask)
    @north = bitmask & MazeConstants::NORTH != 0 ? 1 : 0
    @east = bitmask & MazeConstants::EAST != 0 ? 1 : 0
    @west = bitmask & MazeConstants::WEST != 0 ? 1 : 0
    @south = bitmask & MazeConstants::SOUTH != 0 ? 1 : 0
  end

  def addBitmask(value)
    setBitmask(bitmask | value)
  end

  def to_s
    bitmask.to_s(2)
  end
end

class CustomDungeon
  TEMPLATE_SECTION_WIDTH = 8
  TEMPLATE_SECTION_HEIGHT = 8

  def initialize(map, width, height)
    @map_template = map.clone
    @map = map
    @width = width
    @height = height
    @maze = SpelunkyMaze.new(width, height)
    @start_x = 0
    @start_y = 0
  end

  attr_accessor :start_x
  attr_accessor :start_y

  def generate
    # echoln(@map.data.methods)
    # echoln("inspect")
    # for y in 0..@map.data.ysize
    #   for x in 0..@map.data.xsize
    #     echo @map.data[x,y]
    #     echo " "
    #   end
    #   echoln ""
    # end

    @maze.generate

    @start_x = @maze.start_x * TEMPLATE_SECTION_WIDTH + TEMPLATE_SECTION_WIDTH / 2
    @start_y = @maze.start_y * TEMPLATE_SECTION_HEIGHT + TEMPLATE_SECTION_HEIGHT / 2

    @map.width = @width * TEMPLATE_SECTION_WIDTH
    @map.height = @height * TEMPLATE_SECTION_HEIGHT
    @map.data = Table.new(@map.width, @map.height, 3)

    for y in 0...@height
      for x in 0...@width
        # pick a template section
        # calculate position of template in template map
        mapx = x * TEMPLATE_SECTION_WIDTH
        mapy = y * TEMPLATE_SECTION_HEIGHT
        template = @maze[x, y].bitmask
        templatex = (template % 4) * TEMPLATE_SECTION_WIDTH
        templatey = (template / 4) * TEMPLATE_SECTION_HEIGHT
        # transpose template into map
        for j in 0...TEMPLATE_SECTION_HEIGHT
          for i in 0...TEMPLATE_SECTION_WIDTH
            @map.data[mapx + i, mapy + j, 0] = @map_template.data[templatex + i, templatey + j, 0]
            @map.data[mapx + i, mapy + j, 1] = @map_template.data[templatex + i, templatey + j, 1]
            @map.data[mapx + i, mapy + j, 2] = @map_template.data[templatex + i, templatey + j, 2]
          end
        end
      end
    end
    # echoln(@map.data.inspect)
    # echoln("full inspect")
    # echoln(@map.data.full_inspect)
    # echoln("dump")
    # echoln(@map.data._dump)
  end
end

Events.onMapCreate += proc { |_sender, e|
  mapID = e[0]
  map   = e[1]
  echoln "map #{mapID} #{map}"
  next if !GameData::MapMetadata.exists?(mapID) ||
  !GameData::MapMetadata.get(mapID).random_dungeon
  # this map is a randomly generated dungeon
  dungeon = CustomDungeon.new(map, 8, 8)
  dungeon.generate

  $game_temp.player_new_x = dungeon.start_x
  $game_temp.player_new_y = dungeon.start_y
  # dungeon.generateMapInPlace(map)
  # roomtiles = []
  # # Reposition events
  # for event in map.events.values
  #   tile = pbRandomRoomTile(dungeon, roomtiles)
  #   if tile
  #     event.x = tile[0]
  #     event.y = tile[1]
  #   end
  # end
  # # Override transfer X and Y
  # tile = pbRandomRoomTile(dungeon, roomtiles)
  # if tile
  #   $game_temp.player_new_x = tile[0]
  #   $game_temp.player_new_y = tile[1]
  # end
}