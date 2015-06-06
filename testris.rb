require 'gosu'
CONFIGS = [[1,0,1,1,1,0],[1,1,1,1],[1,0,1,0,1,1],[0,1,0,1,1,1],[1,0,1,1,0,1],[0,1,1,1,1,0],[1,0,1,0,1,0,1,0]]
BOARD_HEIGHT, BOARD_WIDTH, UNIT = 20, 10, 50
class Piece
    attr_reader :r, :c, :width, :config
    def initialize(config=nil)
        @r, @c, @width, @config = 0, 4, 2, config
        @config = CONFIGS[rand(0..CONFIGS.length-1)] if config == nil
        @timer = Gosu::milliseconds()
    end
    def new_index(i, r=@config.length/@width)
        @width * (r - i % r - 1) + i/r
    end
    def rotate_cw
        @config = @config.each_with_index.map{|__,i| @config[new_index(i)]}
        @width = @width != 2 ? 2 : @config.length / @width
    end
    def rotate_ccw
        (1..3).each do rotate_cw end
    end
    def left
        @c -= 1 if (@c > 0)
    end
    def right
        @c += 1 if (@c+@width < BOARD_WIDTH)
    end
    def place(grid)
        drop 0 while not placed? grid
    end
    def draw(ox=0, oy=0, r=-1)
        @config.each_with_index{|bit, i|
           c, r = (i % @width), (i % @width == 0 ? r+1 : r)
           x, y = (@c+c) * UNIT + ox, (@r+r) * UNIT + oy
           Gosu::draw_rect(x,y,UNIT,UNIT,Gosu::Color.argb(0xff_00ff00),3) if bit == 1 }
    end
    def drop(cooldown=500)
        if (Gosu::milliseconds() - @timer) > cooldown
            @r, @timer = @r + 1, Gosu::milliseconds()
        end
    end
    def placed?(grid, r=-1)
       @config.each_with_index{|bit, i| 
          c, r = (i % @width), (i % @width == 0 ? r+1 : r)
          return true if bit == 1 and (@r+r >= BOARD_HEIGHT-1 or grid[@r+r+1][@c+c] == 1) }
       return false
    end
end
class Game
    attr_reader :current, :grid
    def initialize
        @next, @current, @grid = Piece.new, Piece.new, Array.new(20) { Array.new(10) { 0 } }
    end
    def draw
        Gosu::draw_rect(0,0,640,480,Gosu::Color.argb(0xff_000000),0)
        @current.draw
        @grid.each_with_index{|row, i| row.each_with_index{|bit, j|
                Gosu::draw_rect(j*UNIT,i*UNIT,UNIT,UNIT,Gosu::Color.argb(0xff_888888),3) if bit == 1 } }
    end
    def update
        if @current != nil 
            if @current.placed?(@grid)
                r = -1
                @current.config.each_with_index{|bit, i|
                    c, r = (i % @current.width), (i % @current.width == 0 ? r+1 : r)
                    @grid[@current.r + r][@current.c + c] = bit if bit == 1 }
                @current, @next = @next, Piece.new
            end
            (0...BOARD_HEIGHT-@grid.length).each {@grid.unshift([0,0,0,0,0,0,0,0,0,0])} if @grid.delete([1,1,1,1,1,1,1,1,1,1])
            @current.drop
        end
    end
end
class Testris < Gosu::Window
    def initialize
        super 10*UNIT, 20*UNIT
        @cooldown, @last_hit, @game = 100, 0, Game.new
    end
    def update
        if Gosu::milliseconds() - @last_hit > @cooldown
            @game.current.place(@game.grid) if Gosu::button_down? Gosu::KbDown
            @game.current.left if Gosu::button_down? Gosu::KbLeft
            @game.current.right if Gosu::button_down? Gosu::KbRight
            @game.current.rotate_ccw if Gosu::button_down? Gosu::KbUp
            close if Gosu::button_down? Gosu::KbEscape
            @last_hit = Gosu::milliseconds()
        end
        @game.update
    end
    def draw
        @game.draw
    end
end
Testris.new.show
