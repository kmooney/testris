require 'gosu'
CONFIGS = [[2,1,1,0,1,1,1,0],[2,2,1,1,1,1],[2,3,1,0,1,0,1,1],[2,4,0,1,0,1,1,1],[2,5,1,0,1,1,0,1],[2,6,0,1,1,1,1,0],[1,8,1,1,1,1]]
COLORS = [ Gosu::Color.argb(0xff_111111), Gosu::Color.argb(0xff_6600ff), Gosu::Color.argb(0xff_ffff66), Gosu::Color.argb(0xff_66ffff), Gosu::Color.argb(0xff_ff6666), Gosu::Color.argb(0xff_0033cc), Gosu::Color.argb(0xff_ff6666), Gosu::Color.argb(0xff_999966), Gosu::Color.argb(0xff_ff66ff),]
BOARD_HEIGHT, BOARD_WIDTH, UNIT, PADDING = 20, 10, 50, 2  # default: 20, 10, 30
class Piece
    attr_reader :r, :c, :width, :config, :color
    def initialize(config=nil)
        @r, @c, @config = 0, BOARD_WIDTH/2, config
        @config = Array.new(CONFIGS[rand(0..CONFIGS.length-1)]) if config == nil
        @width, @color = @config.shift, @config.shift
        @start_width = @width
        @timer = Gosu::milliseconds()
    end
    def new_index(i, r=@config.length/@width)
        @width * (r - i % r - 1) + i/r
    end
    def rotate_cw
        @config = @config.each_with_index.map{|__,i| @config[new_index(i)]}
        @width = @width != @start_width ? @start_width : @config.length / @width
        @c = BOARD_WIDTH - @width if @c + @width > BOARD_WIDTH
    end
    def rotate_ccw
        (1..3).each do rotate_cw end
    end
    def left(grid)
        @c -= 1 if (@c > 0) and grid[@r][@c-1] == 0
    end
    def right(grid)
        @c += 1 if (@c+@width < BOARD_WIDTH) and grid[@r][@c+1] == 0
    end
    def place(grid)
        drop 0 while not placed? grid
    end
    def draw(ox=0, oy=0, r=-1)
        @config.each_with_index{|bit, i|
           c, r = i % @width, i % @width == 0 ? r+1 : r
           x, y = (@c+c) * UNIT + ox, (@r+r) * UNIT + oy
           Gosu::draw_rect(x,y,UNIT-PADDING,UNIT-PADDING,COLORS[@color],3) if bit != 0 }
    end
    def drop(cooldown=500)
        if Gosu::milliseconds() - @timer > cooldown
            @r, @timer = @r + 1, Gosu::milliseconds()
        end
    end
    def placed?(grid, r=-1)
       @config.each_with_index{|bit, i| 
          c, r = (i % @width), (i % @width == 0 ? r+1 : r)
          return true if bit != 0 and (@r+r >= BOARD_HEIGHT-1 or grid[@r+r+1][@c+c] != 0) }
       return false
    end
end
class Testris < Gosu::Window
    def initialize
        super BOARD_WIDTH*UNIT, BOARD_HEIGHT*UNIT
        @cooldown, @last_hit, @grace_period = 50, 0, 250
        @next, @current, @grid = Piece.new, Piece.new, Array.new(BOARD_HEIGHT+2) { Array.new(BOARD_WIDTH) { 0 } }
        @song = Gosu::Song.new("media/testris.mp3")
        @song.volume=0.03
        @song.play true
        @hooray, @drop_sample, @whoosh = Gosu::Sample.new("media/hooray.wav"), Gosu::Sample.new("media/drop.wav"), Gosu::Sample.new("media/whoosh.wav")
        @played = false
    end
    def button_up(id)
        @current.place(@grid) if id == Gosu::KbDown 
        @current.rotate_ccw if id == Gosu::KbQ 
        @current.rotate_cw if id == Gosu::KbW
    end
    def update(r=-1)
        if Gosu::milliseconds() - @last_hit > @cooldown
            @current.left @grid if Gosu::button_down? Gosu::KbLeft
            @current.right @grid if Gosu::button_down? Gosu::KbRight
            close if Gosu::button_down? Gosu::KbEscape
            @last_hit = Gosu::milliseconds()
        end
        if @current != nil 
            if @current.placed? @grid
                @drop_sample.play 10, 1 if not @played
                @played = true
                @grace_period -= 10
                if @grace_period <= 0
                    @played = false
                    @grace_period = 250
                    @current.config.each_with_index{|bit, i|
                        c, r = (i % @current.width), (i % @current.width == 0 ? r+1 : r)
                        @grid[@current.r + r][@current.c + c] = @current.color if bit != 0 }
                    @current, @next = @next, Piece.new
                end
            end 
            if @grid.select{|row| row.select{|bit| bit == 0} == []}.each{|rr| @grid.delete(rr)} != []
                @whoosh.play if BOARD_HEIGHT-@grid.length != 4
                @hooray.play 0.7, 0.7 if BOARD_HEIGHT-@grid.length == 4
                (0...BOARD_HEIGHT-@grid.length).each {@grid.unshift(Array.new(BOARD_WIDTH){0})}
            end
            @current.drop if not @current.placed? @grid
        end
    end
    def draw
        @grid.each_with_index{|row, i| row.each_with_index{|bit, j|
                Gosu::draw_rect(j*UNIT,i*UNIT,UNIT-PADDING,UNIT-PADDING,COLORS[bit],3) if bit != 0 
                Gosu::draw_rect(j*UNIT,i*UNIT,UNIT-PADDING,UNIT-PADDING,COLORS[0],3) if bit == 0
        } }
        @current.draw
    end
end
Testris.new.show
#TODO - collision detection side-to-side, drop is just "faster", score, title screen, <100 LOC!!