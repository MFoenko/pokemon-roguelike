class MazeConstants
  NORTH = 0b0001
  WEST = 0b0010
  EAST = 0b0100
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

class DungeonPath
  def initialize(length, weights = [1, 1, 1, 1])
    weight_north = weights[0]
    weight_west = weights[2]
    weight_east = weights[1]
    weight_south = weights[3]

    @nodes = []


  end

  class DungeonPathNode
    # should keep traack of position relative to head node
    @north = nil
    @west = nil
    @east = nil
    @south = nil

    attr_accessor :north, :east, :west, :south
  end
end

class SpelunkyMazeCell
  @north = 0
  @west = 0
  @east = 0
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

class DungeonSpec
  @bonus_rate = 5
  def initialize(event = nil)
    next if event.nil?
    page = event.pages[0]
    for command in page.list
      next if command.code != 108 # skip non Comment
      parseCommand(command.parameters[0])
    end
  end

  def self.Default
    DungeonSpec.new
  end

  def parseCommand(command)
    next if text.nil?
    if command[/^BonusRate:*[\s\S]+$/i]
      @bonus_rate = $~[1].to_i
    end
  end

  attr_accessor :bonus_rate
end

class RoomSpec
  @usage = "Path"
  @can_rotate = false
  @scale_difficulty = false
  @difficulty = 1
  def initialize(event)
    page = event.pages[0]
    for command in page.list
      next if command.code != 108 # skip non Comment
      parseCommand(command.parameters[0])
    end
  end

  def parseCommand(command)
    next if text.nil?
    if command[/^CanRotate:*[\s\S]+$/i]
      @can_rotate = $~[1] == "true"
    elsif command[/^ScaleDifficulty:*[\s\S]+$/i]
      @scale_difficulty = $~[1] == "true"
    elsif command[/^Difficulty:*[\s\S]+$/i]
      @difficulty = $~[1].to_i
    end
  end

  attr_accessor :can_rotate, :scale_difficulty, :difficulty
end

class CustomDungeon
  def initialize(map, difficulty, difficulty_max)
    @map_template = map.clone
    @map = map
    @difficulty = difficulty
    @difficulty_max = difficulty_max

    @dungeon_spec = nil
    @rooms = []

    echoln(map.events)

    events = map.events
    for event in events
      if event.name[/^Dungeon/] && @dungeon.nil?
        @dungeon = DungeonSpec.new(event)
      elsif event.name[/^Room/]
        @rooms.push(RoomSpec.new(event))
      end
      echoln(event[1].name)
    end
    if @dungeon_spec.nil?
      @dungeon_spec = DungeonSpec.Default
    end
  end

  def generate
    path_rooms = pick_rooms
    path_length = path_rooms.length
    path = DungeonPath.new(path_length)
    # bonus_count = @difficulty / @dungeon_spec.bonus_rate
    # path.addBonus(bonus_count) if @dungeon_spec.bonus_rate.positive?
    set_rooms(path)
  end

  def pick_rooms
    rooms = []
    remaining_difficulty = @difficulty
    room_pool = []
    while assembled_difficulty > 0
      room_pool = assemble_room_pool(remaining_difficulty, difficulty_max) if room_pool.empty?
      break if room_pool.empty?

      room = room_pool[rand(room_pool.length)]
      rooms.push(room)
      remaining_difficulty -= room.difficulty
      room_pool.keep_if { |v| v.difficulty < remaining_difficulty }
    end
    rooms
  end

  def assemble_room_pool(remaining_difficulty, difficulty_max)
    room_pool = []
    for room in @rooms
      room_pool.push(room) if room.difficulty < difficulty_max && room.difficulty < remaining_difficulty
    end
    room_pool
  end

  def build_path(path_length, weights)
  end
end

Events.onMapCreate += proc { |_sender, e|
  mapID = e[0]
  map   = e[1]
  echoln "map #{mapID} #{map}"
  next if !GameData::MapMetadata.exists?(mapID) ||
  !GameData::MapMetadata.get(mapID).random_dungeon
  # this map is a randomly generated dungeon
  dungeon = CustomDungeon.new(map, 5)


  # $game_temp.player_new_x = dungeon.start_x
  # $game_temp.player_new_y = dungeon.start_y
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