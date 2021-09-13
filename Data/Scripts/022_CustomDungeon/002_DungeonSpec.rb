module SpecHelper
  def self.event_comments_to_map(event)
    map = {}
    return map if event.nil?
    commentPage = event.pages[0]
    for command in page.list
      next if command.code != 108
      next if !command[/^[\S]+:\s?[\S]+$/i]
      key = $~[1]
      val = $~[2]
      if val.to_i.to_s == val
        map[key] = val.to_i
      else
        map[key] = val
      end
    end
    map
  end

end

class DungeonSpec
  include SpecHelper
  def initialize(event = nil)
    @bonus_rate = 5
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

class WallSpec
  def initialize(map, event)
    @x = event.x + 1
    @y = event.y
    @top_height = 0
    @middle_height = 0
    @bottom_height = 1
    echoln( "yo over here #{map.data[@x, @y, 1] }")
    @width = 0
    @width += 1 until map.data[@x + @width, @y, 0] == 0 && map.data[@x + @width, @y, 1] == 0 && map.data[@x + @width, @y, 2] == 0

    echoln event.name
    page = event.pages[0]
    for command in page.list
      echoln "Param #{command.parameters}"
      next if command.code != 108 # skip non Comment
      parseCommand(command.parameters[0])
    end
  end

  def parseCommand(command)
    echoln command
    return if command.nil?
    if command[/^TopHeight:*[\s\S]+$/i]
      @top_height = $~[1].to_i
    elsif command[/^MiddleHeight:*[\s\S]+$/i]
      @middle_height = $~[1].to_i
    elsif command[/^BottomHeight:*[\s\S]+$/i]
      @bottom_height = $~[1].to_i
    end
  end

  def min_height
    @top_height + @bottom_height
  end

  def inspect
    "x=#{!x} y=#{!y} width=#{@width} top_height=#{!top_height} middle_height=#{@middle_height} bottom_height=#{@bottom_height}"
  end

  attr_accessor  :x, :y, :width, :top_height, :middle_height, :bottom_height
end

class DungeonSpec
  def initialize(event = nil)
    @bonus_rate = 5
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

class WallSpec
  def initialize(map, event)
    @x = event.x + 1
    @y = event.y
    @top_height = 0
    @middle_height = 0
    @bottom_height = 1
    echoln( "yo over here #{map.data[@x, @y, 1] }")
    @width = 0
    @width += 1 until map.data[@x + @width, @y, 0] == 0 && map.data[@x + @width, @y, 1] == 0 && map.data[@x + @width, @y, 2] == 0

    echoln event.name
    page = event.pages[0]
    for command in page.list
      echoln "Param #{command.parameters}"
      next if command.code != 108 # skip non Comment
      parseCommand(command.parameters[0])
    end
  end

  def parseCommand(command)
    echoln command
    return if command.nil?
    if command[/^TopHeight:*[\s\S]+$/i]
      @top_height = $~[1].to_i
    elsif command[/^MiddleHeight:*[\s\S]+$/i]
      @middle_height = $~[1].to_i
    elsif command[/^BottomHeight:*[\s\S]+$/i]
      @bottom_height = $~[1].to_i
    end
  end

  def min_height
    @top_height + @bottom_height
  end

  def inspect
    "x=#{!x} y=#{!y} width=#{@width} top_height=#{!top_height} middle_height=#{@middle_height} bottom_height=#{@bottom_height}"
  end

  attr_accessor  :x, :y, :width, :top_height, :middle_height, :bottom_height
end

