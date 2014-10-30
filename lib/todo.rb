class Todo
  # Regular Expressions used in parsing todos
  @@PRIREG=/^\(([A-Z])\)/
  @@CONREG=/@(\w+)/
  @@PROREG=/\+(\w+)/
  @@DONREG=/^x /
  @@SCHEDULEREG=/t:([0-9-]{10})?/

  attr :priority
  attr :contexts
  attr :projects
  attr :done
  attr :schedule
  attr :body

  # Parses text line by line and returns an array of TodoFus
  def self.parse(str)
    ret = []
    str.each_line do |line|
      ret << Todo.new(line)
    end
    ret
  end

  # Parses file line by line and returns an array of TodoFus
  def self.parse_file(fn)
    ret = []
    File.new(fn).read.each_line do |line|
      ret << Todo.new(line)
    end
    ret
  end

  # Constructs a TodoFu from an input string
  def initialize(str)
    s = str.strip.chomp
    @priority = s.scan(@@PRIREG).flatten.first 
    @schedule = s.scan(@@SCHEDULEREG).flatten.first || nil
    @contexts = s.scan(@@CONREG).flatten.uniq || []
    @projects = s.scan(@@PROREG).flatten.uniq || []
    @done = !s.match(@@DONREG).nil?
    @text = s

    @body = s.gsub(@@PRIREG, "")
             .gsub(@@SCHEDULEREG, "")
             .gsub(@@CONREG, "")
             .gsub(@@PROREG, "")
             .gsub(@@DONREG, "")
             .strip
             .chomp

  end

  # Sets/Changes the current priority
  def priority=(pri)
    return false unless pri.is_a?(NilClass) || (pri.is_a?(String) && pri.match(/[A-Z]/))
    @priority = pri
    rebuildText
  end

  # Updates the current contexts
  # * Removes contexts that are no longer needed
  # * Appends new contexts
  def contexts=(cons)
    return false unless cons.is_a? Array
    @contexts=cons.sort!
    rebuildText
  end

  # Updates the current projects
  # * Removes projects that are no longer needed
  # * Appends new projects
  def projects=(projs)
    return false unless projs.is_a? Array
    @projects=projs.sort!
    rebuildText
  end


  def rebuildText
    @text = ""
    if @done
      @text = "x"
    else
      if !@priority.nil?
        @text = "(" + @priority + ")"
      end
    end

    if !@body.nil?
      @text += " " + @body
    end

    if !@contexts.nil?
      @contexts.sort!.each { |context|
        @text += " @" + context
      }
    end

    if !@projects.nil?
      @projects.sort!.each { |project|
        @text += " +" + project
      }
    end

    if !@schedule.nil?
      @text += " t:" + @schedule
    end

  end

  # Returns a String in the following format:
  # (priority) Text with contexts and projects
  def to_s
    rebuildText
    @text
  end

  def do
    @done = true
    rebuildText
  end

  def undo
    @done = false
    rebuildText
  end

  def done?
    @done
  end

  # Compares objects based on priority, with unprioritized
  # objects always losing
  def <=>(b)
    return 1 if @priority.nil?
    return -1 if b.priority.nil?
    @priority <=> b.priority
  end
end
