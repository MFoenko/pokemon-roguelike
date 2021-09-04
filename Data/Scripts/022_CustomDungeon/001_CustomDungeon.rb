class DungeonSpec
  @bonus_rate = 5
  def initialize(event = nil)
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

  attr_accessor :bonus_rate
end

class RoomSpec
  def initialize(event)
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
    echoln @difficulty
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
    for entry in events
      event = entry[1]
      if event.name[/^Dungeon/] && @dungeon.nil?
        @dungeon = DungeonSpec.new(event)
        echoln("Dungeon: #{event.name}")
      elsif event.name[/^Room/]
        @rooms.push(RoomSpec.new(event))
        echoln("Room: #{event.name}")
      end
    end
    if @dungeon_spec.nil?
      @dungeon_spec = DungeonSpec.Default
    end
  end

  def generate
    path_rooms = pick_rooms
    path_length = path_rooms.length
    path = DungeonPath.new(path_length)
    path.generate
    echoln(path)
    # bonus_count = @difficulty / @dungeon_spec.bonus_rate
    # path.addBonus(bonus_count) if @dungeon_spec.bonus_rate.positive?
    # set_rooms(path)
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