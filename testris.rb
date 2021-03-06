require 'gosu'
PIECES = [[2,7,1,0,1,1,1,0],[2,2,1,1,1,1],[2,3,1,0,1,0,1,1],[2,4,0,1,0,1,1,1],[2,5,1,0,1,1,0,1],[2,6,0,1,1,1,1,0],[1,8,1,1,1,1]]
COLORS = [Gosu::Color.argb(0xff_202020), Gosu::Color.argb(0xff_666666), Gosu::Color.argb(0xff_ffff66), Gosu::Color.argb(0xff_66ffff), Gosu::Color.argb(0xff_ff6666), Gosu::Color.argb(0xff_0033cc), Gosu::Color.argb(0xff_ff6666), Gosu::Color.argb(0xff_11aa11), Gosu::Color.argb(0xff_ff66ff)]
BOARD_HEIGHT, BOARD_WIDTH, UNIT, PADDING, LOCK_TIMEOUT = 20, 10, 40, 2, 15
class Piece
    attr_reader :r, :c, :width, :config, :color
    def initialize(config=nil)
        @r, @c, @config = 0, BOARD_WIDTH/2, config
        @config = Array.new(PIECES[rand(0..PIECES.length - 1)]) if config == nil
        @width, @color = @config.shift, @config.shift
        @start_width, @timer = @width, Gosu::milliseconds()
    end
    def check(grid, r=@r-1, *args)
        yield grid
        @config.each_with_index{ |el, i|
            c, r = i % @width + @c, i % @width == 0 ? r + 1 : r
            return false if c < 0 or c >= BOARD_WIDTH or (el != 0 and grid[r][c] == 1) }
        return true
    end
    def rotate_cw(grid, r=@config.length/@width)
        @config = @config.each_with_index.map{|__, i| @config[@width * (r - i % r - 1) + i / r]}
        @width = @width != @start_width ? @start_width : @config.length / @width
        @c = BOARD_WIDTH - @width if @c + @width > BOARD_WIDTH
    end
    def rotate_ccw(grid)
        (1..3).each do rotate_cw grid end
    end
    def left(grid)
        @c -= 1
    end
    def right(grid)
        @c += 1
    end
    def draw(ox=0, oy=0, r=-1)
        @config.each_with_index{|bit, i|
           c, r = i % @width, i % @width == 0 ? r + 1 : r
           x, y = (@c + c + ox) * UNIT, (@r + r + oy) * UNIT
           Gosu::draw_rect(x,y,UNIT-PADDING,UNIT-PADDING,COLORS[@color],3) if bit != 0 }
    end
    def drop(cooldown=500)
        (@r, @timer = @r + 1, Gosu::milliseconds()) if Gosu::milliseconds() - @timer > cooldown
    end
    def placed?(grid, r=-1)
       @config.each_with_index{|bit, i| 
          c, r = (i % @width), (i % @width == 0 ? r + 1 : r)
          return true if bit != 0 and (@r+r >= BOARD_HEIGHT - 1 or grid[@r + r + 1][@c + c] != 0) }
       return false
    end
end
class Testris < Gosu::Window
    def initialize
        super BOARD_WIDTH*3*UNIT/2, BOARD_HEIGHT*UNIT
        @cooldown, @last_hit, @locked, @lock_countdown, @down = 50, 0, false, LOCK_TIMEOUT, false
        @next, @current, @grid, @gameover = Piece.new, Piece.new, Array.new(BOARD_HEIGHT) { Array.new(BOARD_WIDTH) { 0 } }, false
        @lines, @font, @ready = 0, Gosu::Font.new(self, "media/minecraftia.ttf", UNIT), true
    end
    def button_up(id, current_copy=Marshal::load(Marshal::dump(@current)))
        @current.rotate_ccw @grid if id == Gosu::KbQ and current_copy.check(@grid) { |g| current_copy.rotate_ccw g } 
        @current.rotate_cw @grid if id == Gosu::KbW and current_copy.check(@grid) { |g| current_copy.rotate_cw g }
        @lock_countdown = LOCK_TIMEOUT
        (@current, @lines, @grid, @gameover = Piece.new, 0, Array.new(BOARD_HEIGHT) { Array.new(BOARD_WIDTH) {0}}, false) if id == Gosu::KbSpace
    end
    def update(r=-1, current_copy=Marshal::load(Marshal::dump(@current)))
        close if Gosu::button_down? Gosu::KbEscape
        return if @gameover
        if Gosu::milliseconds() - @last_hit > @cooldown
            @current.drop 0 if Gosu::button_down? Gosu::KbDown and not @current.placed? @grid
            @current.left @grid if Gosu::button_down? Gosu::KbLeft and current_copy.check(@grid) {|g| current_copy.left(g)}
            @current.right @grid if Gosu::button_down? Gosu::KbRight and current_copy.check(@grid) {|g| current_copy.right(g)}
            @lock_countdown = LOCK_TIMEOUT if Gosu::button_down? Gosu::KbRight or Gosu::button_down? Gosu::KbLeft
            @last_hit = Gosu::milliseconds()
        end
        if @current != nil 
            @lock_countdown -= 1 if @current.placed? @grid and not @locked and @lock_countdown > 0
            @locked = true if @lock_countdown <= 0
            if @current.placed? @grid and @locked
                @current.config.each_with_index{|bit, i|
                    c, r = (i % @current.width), (i % @current.width == 0 ? r+1 : r)
                    @gameover = true if @grid[@current.r + r][@current.c + c] == 1 and bit != 0
                    @grid[@current.r + r][@current.c + c] = 1 if bit != 0 } if not @gameover
                @current, @next, @locked, @lock_countdown = @next, Piece.new, false, LOCK_TIMEOUT if not @gameover
            end 
            @grid.delete(Array.new(BOARD_WIDTH){1})
            @lines += BOARD_HEIGHT - @grid.length
            (0...BOARD_HEIGHT - @grid.length).each { @grid.unshift(Array.new(BOARD_WIDTH){0}) }
            @current.drop if not @current.placed? @grid and not @gameover
        end
    end
    def draw
        @grid.each_with_index{|row, i| row.each_with_index{|bit, j|
            Gosu::draw_rect(j * UNIT, i * UNIT, UNIT - PADDING, UNIT - PADDING, COLORS[bit], 3) }}
        @current.draw
        @font.draw "Game Over - press space to play again", UNIT*3, UNIT*5, 99 if @gameover
        @font.draw "Lines: #{@lines}", BOARD_WIDTH*UNIT+UNIT/10, 0, 99 if not @gameover
        @font.draw "Next", BOARD_WIDTH*UNIT+UNIT/10, UNIT*2, 99 if not @gameover
        @next.draw 6.5,2.2 if not @gameover
    end
end
Testris.new.show
