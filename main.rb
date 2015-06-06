require 'gosu'

class MyWindow < Gosu::Window
    def initialize
        super 640, 480
        self.caption = "Gosu World"
        @background_image = Gosu::Image.new("media/Space.png", :tileable => true)
        @player = Player.new
        @player.warp(320,240)
        @star_anim = Gosu::Image::load_tiles("media/Star.png", 25, 25)
        @stars = Array.new
        @font = Gosu::Font.new(20)

    end

    def update
        if Gosu::button_down? Gosu::KbLeft or Gosu::button_down? Gosu::GpLeft then
            @player.turn_left
        end
        if Gosu::button_down? Gosu::KbRight or Gosu::button_down? Gosu::GpRight then
            @player.turn_right
        end
        if Gosu::button_down? Gosu::KbUp or Gosu::button_down? Gosu::GpButton0 then
            @player.accelerate
        end
        @player.move
        @player.collect_stars(@stars)
        if rand(100) < 4 and @stars.size < 25 then
            @stars.push(Star.new(@star_anim))
        end
    end
    
    def draw
        (0..10).each do |i|
            (0..10).each do |j|
                @background_image.draw(i*64,j*48,0)
            end
        end
        @player.draw
        @stars.each{ |star| star.draw }
        @font.draw("Score: #{@player.score}", 10, 10, ZOrder::UI, 1.0, 1.0, 0xff_ffff00)
    end

    def button_down(id)
        if id == Gosu::KbEscape
            close
        end
    end

end

class Player
    def initialize
        @image = Gosu::Image.new("media/StarShip.bmp")
        @beep = Gosu::Sample.new("media/Beep.wav")
        @x = @y = @vel_x = @vel_y = @angle = 0.0
        @turn_angle = 4.5
        @velocity = 0.5
        @score = 0
    end

    def warp(x,y)
        @x, @y = x, y
    end

    def turn_left
        @angle -= @turn_angle
    end

    def turn_right
        @angle += @turn_angle
    end

    def accelerate
        @vel_x += Gosu::offset_x(@angle, 0.5)
        @vel_y += Gosu::offset_y(@angle, 0.5)
    end

    def move
        @x += @vel_x
        @y += @vel_y
        @x %= 640
        @y %= 480
        @vel_x *= 0.95
        @vel_y *= 0.95
    end

    def draw
        @image.draw_rot(@x, @y, 1, @angle)
    end

    def score
        @score
    end

    def collect_stars(stars)
        if stars.reject! {|star| Gosu::distance(@x, @y, star.x, star.y) < 35 } then
            @score += 10
            @beep.play(1, rand(1..3), false)
            @playback_speed += 0.1112
            true
        else
            false
        end
    end
end

module ZOrder
    Background, Stars, Player, UI = *0..3
end

class Star
    attr_reader :x, :y

    def initialize(anim)
        @animation = anim
        @color = Gosu::Color.new(0xff_000000)
        @color.red = rand(256 - 40) + 40
        @color.green = rand(256 - 40) + 40
        @color.blue = rand(256 - 40) + 40
        @x = rand * 640
        @y = rand * 480
    end

    def draw
        img = @animation[Gosu::milliseconds / 100 % @animation.size];
        img.draw(@x - img.width / 2.0, 
                 @y - img.height / 2.0,
                 ZOrder::Stars, 1, 1, @color)
    end
end


window = MyWindow.new
window.show
