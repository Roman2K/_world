String.class_eval do
  def cyan; color 36 end
  def magenta; color 35 end
  def dark; color 2 end
  def yellow; color 33 end

private
  
  def color(code)
    "\e[#{code}m#{self}\e[0m"
  end
end

Array.class_eval do
  def rand
    at(Kernel.rand(size))
  end unless public_method_defined? :rand
end

class World
  def initialize(width, height)
    @board = Board.new(width, height)
    @board.each { |slot| slot.populate! if rand > 0.5 }
  end

  def to_s
    lines = @board.rows.map { |row| row.join }
    lines << ("-" * @board.width) << @stats
    lines.join("\n")
  end

  def tick!
    @board.reverse_each { |slot| slot.tick! }
    @stats =
      Stats.new do |stats|
        @board.each { |slot| creature = slot.creature and stats << creature }
      end
    return self
  end

  class Stats < Struct.new(:avg_health, :max_health, :males, :females)
    def initialize
      super(nil, 0, 0, 0)
      @total_health = 0
      yield self
      self.avg_health = @total_health / total
      @total_health = nil
    end

    def to_s
      "Total: %d (m/f: %.1f) | Health: %.1f (max: %.1f)" % [total, males.to_f / females, avg_health, max_health]
    end

    def total
      males + females
    end

    def <<(creature)
      @total_health += creature.energy
      self.max_health = creature.energy if creature.energy > max_health
      eval("self.#{creature.sex}s += 1")
      return self
    end
  end

  class Creature < Struct.new(:energy, :location)
    def self.random(*args, &block)
      [Male, Female].rand.new(*args, &block)
    end

    def initialize(energy=100-rand(5))
      super
    end

    def to_s
      case energy
      when 0..20 then "."
      when 21..40 then "o"
      when 41..60 then "O"
      else "@"
      end
    end

    def tick!
      if location && (energy < 80 || rand < 0.4) && rand > 0.2
        target = location.next
        if other = target.creature
          interact_with! other
        else
          self.energy *= 1.0 - (0.01 * body_count)
          target.populate_with! location.empty!
        end
      end
      return self
    end

  protected

    def interact_with!(other)
      if sex != other.sex && parent = [self, other].find { |c| c.respond_to?(:can_become_pregnant?) && c.can_become_pregnant? }
        if energy > (required = Female::LITTER_SIZE * Baby::INITIAL_ENERGY) && rand > 0.25
          withdraw_energy! required
          parent.become_pregnant!
        else
          fight! other
        end
      elsif energy > other.energy || rand < 0.2
        fight! other
      end
    end

    def fight!(other)
      recipient, source = if other.energy < energy && rand > 0.25 then [self, other] else [other, self] end
      recipient.acquire_energy_from! source
    end

    def withdraw_energy!(amount)
      amount = [energy, amount].min
      self.energy -= amount
      location.empty! if location && energy <= 0
      return amount
    end

    def empty_energy!
      withdraw_energy! energy
    end

    def acquire_energy_from!(other)
      amount = other.withdraw_energy! energy * 0.05
      self.energy += amount
    end

    class Male < self
      def initialize(*args, &block)
        super
        self.energy *= 1.2
      end

      def to_s
        super.cyan
      end

      def sex
        :male
      end

      def body_count
        1
      end
    end

    class Female < self
      LITTER_SIZE = 3

      def to_s
        pregnant? ? super.yellow : super.magenta
      end

      def sex
        :female
      end

      def body_count
        1 + babies.size
      end

      def tick!
        babies.dup.each { |baby| baby.tick! }
        super
      end

      def can_become_pregnant?
        !pregnant?
      end

      def pregnant?
        !babies.empty?
      end

      def become_pregnant!
        if can_become_pregnant?
          LITTER_SIZE.times { babies << Baby.new(self) }
        end
        return self
      end

    protected

      def deliver!(baby)
        babies.include? baby or raise IndexError, "baby not being carried"
        if location && (destination = location.next).empty?
          withdraw_energy! Baby::INITIAL_ENERGY / 2.0
          babies.delete(baby)
          destination.populate_with! baby.creature
        end
      end

      def get_rid_of!(baby)
        babies.delete(baby) or raise IndexError, "baby not being carried"
        self.energy += baby.creature.empty_energy!
        return self
      end

    private

      def babies
        @babies ||= []
      end
    end

    class Baby < Struct.new(:parent, :creature)
      INITIAL_ENERGY = 10

      def initialize(parent)
        super(parent, Creature.random(INITIAL_ENERGY))
      end

      def tick!
        creature.energy += 10
        if creature.energy >= 40
          baby = self
          delivered = parent.instance_eval { deliver! baby }
          if !delivered && creature.energy >= 50
            parent.instance_eval { get_rid_of! baby }
          end
        end
      end
    end
  end

  class Board
    include Enumerable

    def initialize(width, height)
      @map = []
      height.to_i.times do |y|
        @map.push(row = [])
        width.to_i.times do |x|
          row << Slot.new(self, x, y)
        end
      end
    end

    def width
      @map[0].size
    end

    def height
      @map.size
    end

    def rows
      @map.dup
    end

    def each(*args, &block)
      iterate(:each, *args, &block)
    end

    def reverse_each(*args, &block)
      iterate(:reverse_each, *args, &block)
    end

    def next_to(slot)
      x, y = slot.coordinates
      x += 1
      if x >= width
        x = 0
        y += 1
        if y >= height
          y = 0
        end
      end
      @map[y][x]
    end

  private

    def iterate(iterator, *args, &block)
      @map.send(iterator) { |row| row.send(iterator, *args, &block) }
    end
  end

  class Slot < Struct.new(:board, :x, :y, :creature)
    def to_s
      (creature || " ").to_s
    end

    def coordinates
      [x, y]
    end

    def populate!
      populate_with! Creature.random
    end

    def populate_with!(creature)
      self.creature = creature
      creature.location = self
      return self
    end

    def empty!
      removed, self.creature = self.creature, nil
      removed.location = nil
      return removed
    end

    def empty?
      creature.nil?
    end

    def next
      board.next_to(self)
    end

    def tick!
      creature.tick! if creature
    end
  end
end

if $0 == __FILE__
  require "optparse"

  height = 16
  width = 32
  fps = 10
  OptionParser.new do |opts|
    opts.on("--height HEIGHT", Integer) { |h| height = h }
    opts.on("--width WIDTH", Integer) { |w| width = w }
    opts.on("--fps FPS", Integer) { |f| fps = f }
    opts.parse!
  end

  world = World.new(width, height)
  loop do
    world.tick!
    print "\e[H\e[2J\e[H\e[2J", world, "\n"
    sleep 1.0 / fps
  end
end
