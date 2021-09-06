class DungeonSpec
  def initialize(event = nil)
    @bonus_rate = 5
    @wall_width = 2
    @wall_height = 2
    if !event.nil?
      page = event.pages[0]
      for command in page.list
        next if command.code != 108 # skip non Comment
        parseCommand(command.parameters[0])
      end
    end
  end

  def self.Default
    DungeonSpec.new
  end

  def parseCommand(command)
    return if command.nil?
    if command[/^BonusRate:*[\s\S]+$/i]
      @bonus_rate = $~[1].to_i
    end
  end

  attr_accessor :bonus_rate, :wall_width, :wall_height
end

class RoomSpec
  def initialize(map, event)
    @x = event.x + 1
    @y = event.y
    @width = 0
    @width += 1 until map.data[@x + @width, @y, 0] == 0
    @height = 0
    @height += 1 until map.data[@x, @y + @height, 0] == 0

    @usage = 'Path'
    @can_rotate = false
    @scale_difficulty = false
    @difficulty = 1
    echoln event.name
    page = event.pages[0]
    for command in page.list
      echoln "Param #{command.parameters}"
      next if command.code != 108 # skip non Comment
      parseCommand(command.parameters[0])
    end
    echoln "x=#{@x} y=#{@y} width=#{@width} height=#{@height}"
  end

  def parseCommand(command)
    echoln command
    return if command.nil?
    if command[/^CanRotate:*[\s\S]+$/i]
      @can_rotate = $~[1] == "true"
    elsif command[/^ScaleDifficulty:*[\s\S]+$/i]
      @scale_difficulty = $~[1] == "true"
    elsif command[/^Difficulty:*[\s\S]+$/i]
      @difficulty = $~[1].to_i
    end
  end

  attr_accessor :can_rotate, :scale_difficulty, :difficulty, :width, :height, :x, :y
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
    for entry in events
      event = entry[1]
      if event.name[/^Dungeon/] && @dungeon.nil?
        @dungeon = DungeonSpec.new(event)
        echoln("Dungeon: #{event.name}")
      elsif event.name[/^Room/]
        @rooms.push(RoomSpec.new(map, event))
        echoln("Room: #{event.name}")
      end
    end
    if @dungeon_spec.nil?
      @dungeon_spec = DungeonSpec.Default
    end
  end

  def generate
    rooms = pick_rooms
    path_length = rooms.length
    positions = DungeonRoomPositions.new(path_length)
    positions.generate
    positions.normalize
    echoln(positions)
    # bonus_count = @difficulty / @dungeon_spec.bonus_rate
    # path.addBonus(bonus_count) if @dungeon_spec.bonus_rate.positive?
    grid = draw_rooms(positions, rooms)
    write_to_map(grid)

    echo("width=#{@width} height=#{@height}")
  end

  def pick_rooms
    rooms = []
    remaining_difficulty = @difficulty
    room_pool = []
    while remaining_difficulty > 0
      room_pool = assemble_room_pool(remaining_difficulty, @difficulty_max) if room_pool.empty?
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

  def draw_rooms(room_positions, rooms)
    data = FlexGrid.new
    widths = []
    heights = []
    offset_x = [0]
    offset_y = [0]
    for i in 0...room_positions.grid.width
      items = room_positions.grid.items_in_col(i)
      items = items.map { |r| rooms[r].width }
      width = items.max
      widths.push(width)
      offset_x.push(offset_x[-1] + width)
    end

    for i in 0...room_positions.grid.height
      items = room_positions.grid.items_in_row(i)
      items = items.map { |r| rooms[r].height }
      height = items.max
      heights.push(height)
      offset_x.push(offset_x[-1] + height)
    end

    for x in 0...room_positions.grid.width
      for y in 0...room_positions.grid.height
        zone_width = widths[x]
        zone_height = heights[x]
        zone_offset_x = offset_x[x]
        zone_offset_y = offset_y[y]
        room = rooms[room_positions[FlexGrid::Coord.new(x,y)]]
        width_variability = zone_width - room.width
        height_variability = zone_height - room.height
        data.draw_rectangle(zone_offset_x + rand(width_variability), zone_offset_y + rand(height_variability), room.width, room.height, map_template, room.x, room.y)
      end
    end
    data
  end

  def write_to_map(grid)
    grid.normalize
    @map.width = grid.width
    @map.height = grid.height
    @map.data = Table.new(grid.width, grid.height, 3)
    for x in 0...grid.width
      for y1 in 0...grid.height
        y = grid.height - 1 - y1
        d = grid[FlexGrid::Coord.new(x, y)]
        next if d.nil?
        @map.data[x, y, 0] = d[0]
        @map.data[x, y, 1] = d[1]
        @map.data[x, y, 2] = d[2]
        # echoln("#{d} #{d[0]} #{d[1]} #{d[2]}")
      end
    end
  end
  # def set_rooms(room_positions)
  #   for coord in room_positions.path
  #     coord.
  #   end
  # end
end

Events.onMapCreate += proc { |_sender, e|
  mapID = e[0]
  map   = e[1]
  echoln "map #{mapID} #{map}"
  next if !GameData::MapMetadata.exists?(mapID) ||
  !GameData::MapMetadata.get(mapID).random_dungeon
  # this map is a randomly generated dungeon
  dungeon = CustomDungeon.new(map, 20, 2)
  dungeon.generate

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