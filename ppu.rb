Registers = [0x2000,0x2001,0x2002,0x2003,0x2004,0x2005,0x2006,0x2007,0x4014]

class Ppu
<<<<<<< HEAD
attr_accessor :ppu
attr_accessor :registers
attr_accessor :screen


def initialize()
	@ppu = [0]*0x4000
	@registers = {}
	Registers.each {|adresse| @registers[adresse] = 0}
	init_affichage
end


def init_affichage()
	SDL.init SDL::INIT_VIDEO
	@screen = SDL::set_video_mode 256, 240, 32, SDL::SWSURFACE
	reset_pixel
end


def reset_pixel()
	@x = @y = 0
end


def get_bit(liste_octets,ligne,bit)
	return (liste_octets[ligne].bit?(7-bit) | liste_octets[ligne+8].bit?(7-bit) << 1)
end

def get_pixel(x,y)
	set_tables
	pos_tile = (y/8)*32+(x/8)
	index = @table_nommage_screen[pos_tile] * 16
	pixel = get_bit(@screen_pattern_table[index..index+15],y%8,x%8)
	return pixel
=======
	attr_accessor :ppu
	attr_accessor :registers
	attr_accessor :screen
>>>>>>> 124c499b84f9088ffdb0d58c7131459d5d723e50
	
	
	def initialize()
		@ppu = [0]*100000
		@registers = {}
		Registers.each {|adresse| @registers[adresse] = 0}
		init_affichage
	end
	
	
	def init_affichage()
		SDL.init SDL::INIT_VIDEO
		@screen = SDL::set_video_mode 256, 240, 32, SDL::SWSURFACE
		reset_pixel
	end
	
	
	def reset_pixel()
		@x = @y = 0
	end
	
<<<<<<< HEAD
	@sprite_size = @registers[0x2000].bit?(5)

	@table_nommage_screen = @ppu[0x2000..0x23C0]   if @registers[0x2000].bit?(1) == 0 and @registers[0x2000].bit?(0) == 0
	@table_nommage_screen = @ppu[0x2400..0x27C0]   if @registers[0x2000].bit?(1) == 0 and @registers[0x2000].bit?(0) == 1
	@table_nommage_screen = @ppu[0x2800..0x2BC0]   if @registers[0x2000].bit?(1) == 1 and @registers[0x2000].bit?(0) == 0
	@table_nommage_screen = @ppu[0x2C00..0x2FC0]   if @registers[0x2000].bit?(1) == 1 and @registers[0x2000].bit?(0) == 1
	

end


def set_vblank()
	@registers[0x2002] = @registers[0x2002].set_bit(7) #Set du Vblank
end

def clear_vblank()
	@registers[0x2002] = @registers[0x2002].clear_bit(7) #Clear du Vblank
end


def draw_screen()
	@screen.putPixel(@x,@y,color?(get_pixel(@x,@y)))
	@x+=1
	if @x>255
		@x = 0
		@y+=1
	elsif @y>239
		reset_pixel
=======
	
	def get_bit(liste_octets,ligne,bit)
		return (liste_octets[ligne].bit?(7-bit) | liste_octets[ligne+8].bit?(7-bit) << 1)
	end
	
	def get_pixel(x,y)
		set_tables
		pos_tile = (y/8)*32+(x/8)
		index = @table_nommage_screen[pos_tile] * 16
		pixel = get_bit(@screen_pattern_table[index..index+15],y%8,x%8)
		return pixel	
	end
	
	
	def color?(color)
		rgb = case color
			when 0 then [124,124,124]
			when 1 then [0,0,22]
			when 2 then [0,0,18]
			when 3 then [64,40,188]
		end
		return rgb
	end
	
	
	def set_tables()
		@sprite_pattern_table = case @registers[0x2000].bit?(3)
			when 0 then @ppu[0x0..0x0FFF]
			when 1 then @ppu[0x1000..0x1FFF]
		end
	
		@screen_pattern_table = case @registers[0x2000].bit?(4)
			when 0 then @ppu[0x0..0x0FFF]
			when 1 then @ppu[0x1000..0x1FFF]
		end
		
		@sprite_size = @registers[0x2000].bit?(5)
		
		if @registers[0x2000].bit?(1) == 0 and @registers[0x2000].bit?(0) == 0
			@table_nommage_screen = @ppu[0x2000..0x23C0]
		elsif @registers[0x2000].bit?(1) == 0 and @registers[0x2000].bit?(0) == 1
			@table_nommage_screen = @ppu[0x2400..0x27C0]
		elsif @registers[0x2000].bit?(1) == 1 and @registers[0x2000].bit?(0) == 0
			@table_nommage_screen = @ppu[0x2800..0x2BC0]
		elsif if @registers[0x2000].bit?(1) == 1 and @registers[0x2000].bit?(0) == 1
			@table_nommage_screen = @ppu[0x2C00..0x2FC0]
		end
	
	end
	
	
	def set_vblank()
		@registers[0x2002] = @registers[0x2002].set_bit(7) #Set du Vblank
	end
	
	
	def clear_vblank()
		@registers[0x2002] = @registers[0x2002].clear_bit(7) #Clear du Vblank
	end
	
	
	def draw_screen()
		@screen.putPixel(@x,@y,color?(get_pixel(@x,@y)))
		@x+=1
		if @x>255
			@x = 0
			@y+=1
		elsif @y>239
			set_vblank
			reset_pixel
			@screen.flip
		end
	
>>>>>>> 124c499b84f9088ffdb0d58c7131459d5d723e50
	end

end
