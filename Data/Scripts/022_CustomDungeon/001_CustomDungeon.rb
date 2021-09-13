class CustomDungeon
  def initialize(map, difficulty, difficulty_max)
    @map_template = map.clone
    @map = map
    @difficulty = difficulty
    @difficulty_max = difficulty_max

    @dungeon_spec = nil
    @rooms = []
    @walls = []

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
      elsif event.name[/^Wall/]
        @walls.push(WallSpec.new(map, event))
        echoln("Wall: #{event.name}")
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
    draw_paths(grid)
    write_to_map(grid)

  end

  def pick_rooms
    rooms = []
    remaining_difficulty = @difficulty
    room_pool = []
    while remaining_difficulty > 0
      room_pool = assemble_room_pool(remaining_difficulty, @difficulty_max) if room_pool.empty?
      break if room_pool.empty?

      room = room_pool.delete_at(rand(room_pool.length))
      echoln room
      rooms.push(room)
      remaining_difficulty -= room.difficulty
      room_pool.keep_if { |v| v.difficulty < remaining_difficulty }
    end
    rooms
  end

  def assemble_room_pool(remaining_difficulty, difficulty_max)
    room_pool = []
    for room in @rooms
      room_pool.push(room) if room.difficulty <= difficulty_max && room.difficulty <= remaining_difficulty
    end
    room_pool
  end

  WALL_HEIGHT = 2
  WALL_WIDTH = 2

  def draw_rooms(room_positions, rooms)
    data = FlexGrid.new
    offsets = []
    widths = []
    heights = []
    offset_x = [0]
    offset_y = [0]
    for i in 0...room_positions.grid.width
      items = room_positions.grid.items_in_col(i)
      items = items.map { |r| rooms[r].width }
      width = items.max
      widths.push(width)
      offset_x.push(offset_x[-1] + width + WALL_WIDTH)
    end

    for i in 0...room_positions.grid.height
      items = room_positions.grid.items_in_row(i)
      items = items.map { |r| rooms[r].height }
      height = items.max
      heights.push(height)
      offset_y.push(offset_y[-1] + height + WALL_HEIGHT)
    end

    # echoln (offset_x)
    # echoln (offset_y)
    # echoln(room_positions.path)

    echoln(room_positions.path)
    for c in room_positions.path
      room = rooms[room_positions.grid[c]]
      zone_width = widths[c.x]
      zone_height = heights[c.y]
      zone_offset_x = offset_x[c.x]
      zone_offset_y = offset_y[c.y]
      # echoln(c)
      width_variability = zone_width - room.width
      height_variability = zone_height - room.height
      x = (width_variability.positive? ? rand(width_variability + 1) : 0)
      y = (height_variability.positive? ? rand(height_variability + 1) : 0)
      data.draw_rectangle(zone_offset_x + x, zone_offset_y + y, room.width, room.height, @map_template.data, room.x, room.y)
      offsets.push(FlexGrid::Coord.new(zone_offset_x + x, zone_offset_y + y))
      # if !prev_room.nil?
      # end
    end

    echoln offsets

    # draw paths between rooms
    for i in 1...room_positions.path.length
      c1 = room_positions.path[i - 1]
      c2 = room_positions.path[i]
      room1 = rooms[i - 1]
      room2 = rooms[i]
      offsets1 = offsets[i - 1]
      offsets2 = offsets[i]
      move = room_positions.moves[i-1]
      start_x = offsets1.x + (move.x == 0 ? rand(room1.width) : move.x.positive? ? room1.width : -1)
      start_y = offsets1.y + (move.y == 0 ? rand(room1.height) : move.y.positive? ? room1.height : -1)
      end_x = offsets2.x + (move.x == 0 ? rand(room2.width) : move.x.negative? ? room2.width : -1)
      end_y = offsets2.y + (move.y == 0 ? rand(room2.height) : move.y.negative? ? room2.height : -1)
      x_vals = [start_x, end_x]
      y_vals = [start_y, end_y]
      path_width = end_x - start_x
      path_height = end_y - start_y

      echoln("#{start_x},#{start_y} to #{end_x},#{end_y}")
      # data[FlexGrid::Coord.new(start_x, start_y)] = [389, 0, 0]
      # data[FlexGrid::Coord.new(end_x, end_y)] = [389, 0, 0]

      if move.y == 0
        for yi in 0..path_height.abs
          y = path_height.positive? ? start_y + yi : end_y + yi
          data[FlexGrid::Coord.new(start_x, y)] = [389, 0, 0]
        end
        for xi in 0..path_width.abs
          x = path_width.positive? ? start_x + xi : end_x + xi
          data[FlexGrid::Coord.new(x, end_y)] = [389, 0, 0]
        end
      elsif move.x == 0
        for xi in 0..path_width.abs
          x = path_width.positive? ? start_x + xi : end_x + xi
          data[FlexGrid::Coord.new(x, start_y)] = [389, 0, 0]
        end
        for yi in 0..path_height.abs
          y = path_height.positive? ? start_y + yi : end_y + yi
          data[FlexGrid::Coord.new(end_x, y)] = [389, 0, 0]
        end
      end
    end

    max_wall_height = @walls.map { |w| w.min_height }.max
    max_wall_width = @walls.map { |w| w.width }.max

    for x in 0...data.width
      for yi in 0...data.height
        y = data.height - 1 - yi
        next if !data[FlexGrid::Coord.new(x, y)].nil? || data[FlexGrid::Coord.new(x, y + 1)].nil?
        echoln "x=#{x} y=#{y} this=#{data[FlexGrid::Coord.new(x, y)]} above=#{data[FlexGrid::Coord.new(x, y + 1)]}"

        for wall in @walls
          echoln "wall=#{wall} empty?=#{data.empty?(x, y - 1, wall.width, wall.min_height)}"

          next if !data.empty?(x, y - 1, wall.width, wall.min_height)
          data.draw_rectangle(x, y - 1, wall.width, wall.bottom_height, @map_template.data, wall.x, wall.y + wall.top_height + wall.middle_height)

        end
      end
    end

    data[FlexGrid::Coord.new(0, 0)] = [392, 0, 0] # debug, draw a tile in the top left corner

    data
  end

  def write_to_map(grid)
    grid.normalize
    @map.width = grid.width
    @map.height = grid.height
    @map.data = Table.new(grid.width, grid.height, 3)
    for x in 0...grid.width
      for y in 0...grid.height
        # y = grid.height - 1 - y1
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