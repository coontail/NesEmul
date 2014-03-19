class Cpu

	attr_accessor :ram
	attr_accessor :cpu
	attr_accessor :ppu


	def initialize(rom)	
		@ram = [0]*100000
		@ppu = Ppu.new
		#@oam = Oam.new
		prg_start_index = map_rom(rom)
		@cpu = {:Y=>0,:X=>0,:A=>0,:S=>255,:P=>0,:compteur=>prg_start_index,:compteur_new=>prg_start_index}
	end


	def map_rom(rom)
		header = rom.shift(16)
		if header[4] == 1
			prg_start_index = 0xC000 #Index de mappage de la PRG (- de 16Ko de PRG)
		else
			prg_start_index = 0x8000 #Index de mappage de la PRG (+ de 16Ko de PRG)
		end
		if header[6].bit?(2) == 1
			trainer = rom.shift(512)
			@ram[0x7000,trainer.length] = trainer # Mapping du trainer dans la RAM
		end
		prg_rom = rom.shift(header[4]*16384)
		chr_rom = rom.shift(header[5]*8192)
		@ppu.ppu[0,chr_rom.length] = chr_rom
		@ram[prg_start_index,prg_rom.length] = prg_rom # Mapping de la PRG dans la RAM
		return prg_start_index
	end


	def nmi_interrupt()
		bytefort = @cpu[:compteur_new] >> 8
		bytefaible = @cpu[:compteur_new] & 0x00FF
		@ram[@cpu[:S]+0x100] = bytefort # octet de poids fort
		@cpu[:S] -= 1 #decrementation pour la prochaine valeur
		@ram[@cpu[:S]+0x100] = bytefaible #octet de poids faible
		@cpu[:S] -= 1
		@ram[@cpu[:S]+0x100] = @cpu[:P] #status
		@cpu[:S] -= 1
		@cpu[:compteur_new] = @ram[0xFFFA]+(@ram[0xFFFB]*256)
		#@cpu[:P] = @cpu[:P].set_bit(2)
	end


	def reset_rom()
		reset_address = @ram[0xFFFC]+(@ram[0xFFFD]*256)
		@cpu[:compteur] = @cpu[:compteur_new] = reset_address
	end


	def cmp(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_carry @cpu[:A].int8_minus signed case opcode
			when "C9" then arg1
			when "C5" then read(arg1)
			when "D5" then read(arg1+@cpu[:X])
			when "CD" then read(arg1+(arg2*256))
			when "DD" then read(arg1+(arg2*256)+@cpu[:X])
			when "D9" then read(arg1+(arg2*256)+@cpu[:Y])
			when "C1" then read(read(arg1+@cpu[:X]) + (read(arg1+@cpu[:X]+1)*256))
			when "D1" then read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y])
		end
	end


	def asl(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_set_switch case zone
			when 0x0A then @cpu[:A] << 1
			when 0x06 then write(arg1,read(arg1) << 1)
			when 0x16 then write(arg1+@cpu[:X], read(arg1+@cpu[:X]) << 1)
			when 0x0E then write(arg1+(arg2*256),read(arg1+(arg2*256)) << 1)
			when 0x1E then write(arg1+(arg2*256)+@cpu[:X],read(arg1+(arg2*256)+@cpu[:X]) << 1)
		end
	end


	def rol(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_set case opcode
			when "2A" then @cpu[:A] = rotate_left(@cpu[:A])
			when "26" then write(arg1,rotate_left(read(arg1)))
			when "36" then write(arg1+@cpu[:X], rotate_left(read(arg1+@cpu[:X])))
			when "2E" then write(arg1+(arg2*256), rotate_left(read(arg1+(arg2*256))))
			when "3E" then write(arg1+(arg2*256)+@cpu[:X], rotate_left(read(arg1+(arg2*256)+@cpu[:X])))
		end
	end


	def ror(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_set case opcode
			when "6A" then @cpu[:A] = rotate_right(@cpu[:A])
			when "66" then write(arg1,rotate_right(read(arg1)))
			when "76" then write(arg1+@cpu[:X], rotate_right(read(arg1+@cpu[:X])))
			when "6E" then write(arg1+(arg2*256), rotate_right(read(arg1+(arg2*256))))
			when "7E" then write(arg1+(arg2*256)+@cpu[:X], rotate_right(read(arg1+(arg2*256)+@cpu[:X])))
		end
	end


	def rotate_left(byte)
		byte.bit?(7) == 1 ? @cpu[:P] = @cpu[:P].set_bit(0) : @cpu[:P] = @cpu[:P].clear_bit(0)
		@cpu[:P].bit?(0) == 1 ? byte = ((byte << 1)&0xFF)| 1 : byte = ((byte << 1)&0xFF)| 0
		@cpu[:P] = @cpu[:P].clear_bit(0) if byte.bit?(7) == 0 #clear carry
		@cpu[:P] = @cpu[:P].set_bit(0) if byte.bit?(7) == 1 #set carry
		return byte
	end

	def rotate_right(byte)
		byte.bit?(0) == 1 ? @cpu[:P] = @cpu[:P].set_bit(0) : @cpu[:P] = @cpu[:P].clear_bit(0)
		@cpu[:P].bit?(0) ==1 ? byte = (byte >> 1)| 128 : byte = (byte >> 1)| 0
		@cpu[:P] = @cpu[:P].clear_bit(0) if byte.bit?(0) == 0 #clear carry
		@cpu[:P] = @cpu[:P].set_bit(0) if byte.bit?(0)==1 #set carry
		return byte
	end


	def lsr(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_set_switch case opcode
			when "4A" then @cpu[:A] = @cpu[:A] >> 1
			when "46" then write(arg1,read(arg1) >> 1)
			when "56" then write(arg1+@cpu[:X], read(arg1+@cpu[:X]) >> 1)
			when "4E" then write(arg1+(arg2*256),read(arg1+(arg2*256)) >> 1)
			when "5E" then write(arg1+(arg2*256)+@cpu[:X], read(arg1+(arg2*256)+@cpu[:X]) >> 1)
		end
	end


	def cpx(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_carry @cpu[:X].int8_minus signed case opcode
			when "E0" then arg1
			when "E4" then read(arg1)
			when "EC" then read(arg1+(arg2*256))
		end	
	end


	def cpy(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_carry @cpu[:Y].int8_minus signed case opcode
			when "C0" then arg1
			when "C4" then read(arg1)
			when "CC" then read(arg1+(arg2*256))
		end	
	end


	def and(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		@cpu[:A] = @cpu[:A] & case opcode
			when "29" then arg1
			when "25" then read(arg1)
			when "35" then read(arg1+@cpu[:X])
			when "2D" then read(arg1+(arg2*256))
			when "3D" then read(arg1+(arg2*256)+@cpu[:X])
			when "39" then read(arg1+(arg2*256)+@cpu[:Y])
			when "21" then read(read(arg1+@cpu[:X]) + read(arg1+@cpu[:X]+1)*256)
			when "31" then read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y])
		end
		sign_zero_set(@cpu[:A])
	end

	def eor(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		@cpu[:A] = @cpu[:A] ^ case opcode
			when "49" then arg1
			when "45" then read(arg1)
			when "55" then read(arg1+@cpu[:X])
			when "4D" then read(arg1+(arg2*256))
			when "5D" then read(arg1+(arg2*256)+@cpu[:X])
			when "59" then read(arg1+(arg2*256)+@cpu[:Y])
			when "41" then read(read(arg1+@cpu[:X]) + read(arg1+@cpu[:X]+1)*256)
			when "51" then read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y])
		end
		sign_zero_set(@cpu[:A])
	end


	def ora(zone,arg1,arg2)
		@cpu[:A] |= case zone
			when 0x09 then arg1
			when 0x05 then read(arg1)
			when 0x15 then read(arg1+@cpu[:X])
			when 0x0D then read(arg1+(arg2*256))
			when 0x1D then read(arg1+(arg2*256)+@cpu[:X])
			when 0x19 then read(arg1+(arg2*256)+@cpu[:Y])
			when 0x01 then read(read(arg1+@cpu[:X]) + read(arg1+@cpu[:X]+1)*256)
			when 0x11 then read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y])
		end
		sign_zero_set(@cpu[:A])
	end

	
	def clc(x,y,z)
		@cpu[:P] = @cpu[:P].clear_bit(0)
	end

	def sec(x,y,z)
		@cpu[:P] = @cpu[:P].set_bit(0)
	end

	def cli(x,y,z)
		@cpu[:P] = @cpu[:P].clear_bit(2)
	end

	def sei(x,y,z)
		@cpu[:P] = @cpu[:P].set_bit(2)
	end

	def clv(x,y,z)
		@cpu[:P] = @cpu[:P].clear_bit(6)
	end

	def cld(x,y,z)
		@cpu[:P] = @cpu[:P].clear_bit(3)
	end

	def sed(x,y,z)
		@cpu[:P] = @cpu[:P].set_bit(3)
	end

	def nop(x,y,z)
	end

	def bit(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		case opcode
		when "24"
			valeur = read(arg1)
			if valeur.bit?(7) == 0
				@cpu[:P] = @cpu[:P].clear_bit(7) #clear
			else
				@cpu[:P] = @cpu[:P].set_bit(7)	 #set
			end
			if valeur.bit?(6) == 0
				@cpu[:P] = @cpu[:P].clear_bit(6) #clear
			else
				@cpu[:P] = @cpu[:P].set_bit(6)	 #set
			end
			if valeur & @cpu[:A] == 0
				@cpu[:P] = @cpu[:P].set_bit(1)	 #set
			else
				@cpu[:P] = @cpu[:P].clear_bit(1) #clear
			end
		when "2C"
			valeur = read(arg1+(arg2*256))	
			if valeur.bit?(7) == 0
				@cpu[:P] = @cpu[:P].clear_bit(7) #clear
			else
				@cpu[:P] = @cpu[:P].set_bit(7)	 #set
			end
			if valeur.bit?(6) == 0
				@cpu[:P] = @cpu[:P].clear_bit(6) #clear
			else
				@cpu[:P] = @cpu[:P].set_bit(6)	 #set
			end
			if valeur & @cpu[:A] == 0
				@cpu[:P] = @cpu[:P].set_bit(1) 	 #set
			else
				@cpu[:P] = @cpu[:P].clear_bit(1) #clear
			end
		end
	end


	###Rappel : dans 0xC0E1 , C0 est l'octet de poids fort et E1 celui de poids faible

	def jsr(zone,arg1,arg2)
		adresse = @cpu[:compteur_new] -1
		bytefort = adresse >> 8 #byte fort
		bytefaible = adresse & 0x00FF #byte faible
		@ram[@cpu[:S]+0x100] = bytefort # adresse actuelle
		@cpu[:S] -= 1 #decrementation pour la prochaine valeur
		@ram[@cpu[:S]+0x100] = bytefaible
		@cpu[:S] -= 1
		@cpu[:compteur_new] = arg1+(arg2*256)
	end

	def rts(zone,arg1,arg2)
		bytefaible = @ram[@cpu[:S]+1+0x100]
		bytefort = @ram[@cpu[:S]+2+0x100]
		@cpu[:compteur_new] = bytefaible+(bytefort*256) +1
		@cpu[:S]+=2 # pour ecraser l'adresse précédente sur 2x8bits
	end

	def rti(zone,arg1,arg2)
		bytefort = @ram[@cpu[:S]+3+0x100]
		bytefaible = @ram[@cpu[:S]+2+0x100]
		status = @ram[@cpu[:S]+1+0x100]
		@cpu[:compteur_new] = bytefaible+(bytefort*256)
		@cpu[:P] = status #récup du status
		@cpu[:S]+=3 # pour ecraser l'adresse précédente sur 3x8bits
	end

	def brk(x,y,z)
	#Interruption push d'abord l'octet de poids fort ensuite octet de pds faible ensuite le status
		bytefort = @cpu[:compteur_new] >> 8
		bytefaible = @cpu[:compteur_new] & 0x00FF
		@ram[@cpu[:S]+0x100] = bytefort # octet de poids fort
		@cpu[:S] -= 1 #decrementation pour la prochaine valeur
		@ram[@cpu[:S]+0x100] = bytefaible #octet de poids faible
		@cpu[:S] -= 1
		@ram[@cpu[:S]+0x100] = @cpu[:P] #status
		@cpu[:S] -= 1
		@cpu[:compteur_new] = read(0xFFFE)+(read(0xFFFF)*256)
		@cpu[:P] = @cpu[:P].set_bit(4)
	end

	def php(x,y,z)
	end

	def jmp(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		@cpu[:compteur_new] = case opcode
			when "4C" then arg1+(arg2*256)
			when "6C" then read(arg1+(arg2*256))+(read(arg1+(arg2*256)+1)*256)
		end
	end

	def adc(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		accumulator_temp = @cpu[:A]
		@cpu[:P].bit?(0) == 1 ? valeur_carry = 1 : valeur_carry = 0
		@cpu[:A] = @cpu[:A].int8_plus case opcode
			when "69" then arg1.int8_plus(valeur_carry)
			when "65" then read(arg1).int8_plus(valeur_carry)
			when "75" then read(arg1+@cpu[:X]).int8_plus(valeur_carry)
			when "6D" then read(arg1+(arg2*256)).int8_plus(valeur_carry)
			when "7D" then read(arg1+(arg2*256)+@cpu[:X]).int8_plus(valeur_carry)
			when "79" then read(arg1+(arg2*256)+@cpu[:Y]).int8_plus(valeur_carry)
			when "61" then read(read(arg1+@cpu[:X]) + (read(arg1+@cpu[:X]+1)*256)).int8_plus(valeur_carry)
			when "71" then read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y]).int8_plus(valeur_carry)
		end
		@cpu[:P] = @cpu[:P].clear_bit(0) #clear the carry
		set_overflow(accumulator_temp)
		sign_zero_clear_or_set(@cpu[:A])
	end

	def sbc(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		accumulator_temp = @cpu[:A]
		@cpu[:P].bit?(0) == 1 ? valeur_carry = 1 : valeur_carry = 0
		@cpu[:A] = @cpu[:A].int8_minus case opcode
			when "E9" then arg1.int8_minus(valeur_carry)
			when "E5" then read(arg1).int8_minus(valeur_carry)
			when "F5" then read(arg1+@cpu[:X]).int8_minus(valeur_carry)
			when "ED" then read(arg1+(arg2*256)).int8_minus(valeur_carry)
			when "FD" then read(arg1+(arg2*256)+@cpu[:X]).int8_minus(valeur_carry)
			when "F9" then read(arg1+(arg2*256)+@cpu[:Y]).int8_minus(valeur_carry)
			when "E1" then read(read(arg1+@cpu[:X]) + (read(arg1+@cpu[:X]+1)*256)).int8_minus(valeur_carry)
			when "F1" then read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y]).int8_minus(valeur_carry)
		end
		@cpu[:P] = @cpu[:P].set_bit(0) #set the carry
		set_overflow(accumulator_temp)
		sign_zero_clear_or_set(@cpu[:A])
	end

	def dec(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_clear_or_set case opcode
			when "C6" then write(arg1,read(arg1).int8_minus(1))
			when "D6" then write(arg1+@cpu[:X],read(arg1+@cpu[:X]).int8_minus(1))
			when "CE" then write(arg1+(arg2*256),read(arg1+(arg2*256)).int8_minus(1))
			when "DE" then write(arg1+(arg2*256)+@cpu[:X],read(arg1+(arg2*256)+@cpu[:X]).int8_minus(1))
		end
	end

	def inc(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		sign_zero_clear_or_set case opcode
			when "E6" then write(arg1,read(arg1).int8_plus(1))
			when "F6" then write(arg1+@cpu[:X],read(arg1+@cpu[:X]).int8_plus(1))
			when "EE" then write(arg1+(arg2*256),read(arg1+(arg2*256)).int8_plus(1))
			when "FE" then write(arg1+(arg2*256)+@cpu[:X],read(arg1+(arg2*256)+@cpu[:X]).int8_plus(1))
		end
	end

	def lda(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		@cpu[:A] = case opcode
			when "A9" then arg1
			when "A5" then read(arg1)
			when "B5" then read(arg1+@cpu[:X])
			when "AD" then read(arg1+(arg2*256))
			when "BD" then read(arg1+(arg2*256)+@cpu[:X])
			when "B9" then read(arg1+(arg2*256)+@cpu[:Y])
			when "A1" then read(read(arg1+@cpu[:X]) + (read(arg1+@cpu[:X]+1)*256))
			when "B1" then read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y])
		end
		sign_zero_set(@cpu[:A])
	end

	def ldx(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		@cpu[:X] = case opcode
			when "A2" then arg1
			when "A6" then read(arg1)
			when "B6" then read(arg1+@cpu[:Y])
			when "AE" then read(arg1+(arg2*256))
			when "BE" then read(arg1+(arg2*256)+@cpu[:Y])
		end
		sign_zero_set(@cpu[:X])
	end

	def ldy(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		@cpu[:Y] = case opcode
			when "A0" then arg1
			when "A4" then read(arg1)
			when "B4" then read(arg1+@cpu[:X])
			when "AC" then read(arg1+(arg2*256))
			when "BC" then read(arg1+(arg2*256)+@cpu[:X])
		end
		sign_zero_set(@cpu[:Y])
	end


	def sta(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		case opcode
			when "85" then write(arg1,@cpu[:A])
			when "95" then write(arg1+@cpu[:X],@cpu[:A])
			when "8D" then write(arg1+(arg2*256),@cpu[:A])
			when "9D" then write(arg1+(arg2*256)+@cpu[:X], @cpu[:A])
			when "99" then write(arg1+(arg2*256)+@cpu[:Y], @cpu[:A])
			when "81" then write(read(read(arg1+@cpu[:X]) + (read(arg1+@cpu[:X]+1)*256)),@cpu[:A])
			when "91" then write(read(read(arg1)+(read(arg1+1)*256)+@cpu[:Y]), @cpu[:A])
		end
		sign_zero_set(@cpu[:A])
	end

	def stx(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		case opcode
			when "86" then write(arg1, @cpu[:X])
			when "96" then write(arg1+@cpu[:Y], @cpu[:X])
			when "8E" then write(arg1+(arg2*256),@cpu[:X])
		end
		sign_zero_set(@cpu[:X])
	end

	def sty(zone,arg1,arg2)
		opcode = zone.to_s(16).upcase
		case opcode
			when "84" then write(arg1, @cpu[:Y])
			when "94" then write(arg1+@cpu[:X], @cpu[:Y])
			when "8C" then write(arg1+(arg2*256),@cpu[:Y])
		end
		sign_zero_set(@cpu[:Y])
	end



	def tax(x,y,z)
		@cpu[:X] = @cpu[:A]
		sign_zero_set(@cpu[:X])
	end

	def txa(x,y,z)
		@cpu[:A] = @cpu[:X]
		sign_zero_set(@cpu[:A])
	end

	def dex(x,y,z)
		@cpu[:X] = @cpu[:X].int8_minus(1)
		sign_zero_clear_or_set(@cpu[:X])
	end

	def inx(x,y,z)
		@cpu[:X] = @cpu[:X].int8_plus(1)
		sign_zero_clear_or_set(@cpu[:X])
	end

	def tay(x,y,z)
		@cpu[:Y] = @cpu[:A]
		sign_zero_set(@cpu[:Y])
	end

	def tya(x,y,z)
		@cpu[:A] = @cpu[:Y]
		sign_zero_set(@cpu[:A])
	end

	def dey(x,y,z)
		@cpu[:Y] = @cpu[:Y].int8_minus(1)
		sign_zero_clear_or_set(@cpu[:Y])
	end

	def iny(x,y,z)
		@cpu[:Y] = @cpu[:Y].int8_plus(1)
		sign_zero_clear_or_set(@cpu[:Y])
	end

	def txs(x,y,z)
		@cpu[:S] = @cpu[:X]
	end

	def tsx(x,y,z)
		@cpu[:X] = @cpu[:S]
	end

	def pha(x,y,z)
		@ram[@cpu[:S]+0x100] = @cpu[:A]
		@cpu[:S] -= 1
	end

	def pla(x,y,z)
		@cpu[:A] = @ram[@cpu[:S]+1+0x100]	#dernier elem
		@cpu[:S] += 1
	end

	def php(x,y,z)
		@ram[@cpu[:S]+0x100] = @cpu[:P]
		@cpu[:S] -= 1
	end

	def plp(x,y,z)
		@cpu[:A] = @ram[@cpu[:S]+1+0x100]
		@cpu[:S] += 1	

	end

	def bcc(zone,arg1,arg2)
		if @cpu[:P].bit?(0) == 0
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end

	def bcs(zone,arg1,arg2)
		if @cpu[:P].bit?(0) == 1
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end

	def bvc(zone,arg1,arg2)
		if @cpu[:P].bit?(6) == 0
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end

	def bvs(zone,arg1,arg2)
		if @cpu[:P].bit?(6) == 1
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end

	def bpl(zone,arg1,arg2)
		if @cpu[:P].bit?(7) == 0
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end

	def bmi(zone,arg1,arg2)
		if @cpu[:P].bit?(7) == 1
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end

	def bne(zone,arg1,arg2)
		if @cpu[:P].bit?(1) == 0
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end

	def beq(zone,arg1,arg2)
		if @cpu[:P].bit?(1) == 1
			@cpu[:compteur_new] = @cpu[:compteur_new]+signed(arg1)
		end
	end


	def set_overflow(byte)
		if @cpu[:A].bit?(6) != byte.bit?(6)
			@cpu[:P] = @cpu[:P].set_bit(6)
		end
	end


	def sign_zero_carry(byte)
		if byte & 0x80 == 0
			@cpu[:P] = @cpu[:P].set_bit(0)
			@cpu[:P] = @cpu[:P].clear_bit(7)
			@cpu[:P] = @cpu[:P].clear_bit(1)
		elsif byte == 0
			@cpu[:P] = @cpu[:P].set_bit(0)
			@cpu[:P] = @cpu[:P].clear_bit(7)
			@cpu[:P] = @cpu[:P].set_bit(1)
		elsif byte & 0x80 != 0
			@cpu[:P] = @cpu[:P].clear_bit(0)
			@cpu[:P] = @cpu[:P].set_bit(7)
			@cpu[:P] = @cpu[:P].clear_bit(1)
		end
	end

	def sign_zero_clear_or_set(byte) #Clears or sets flag 
		if byte==0
			@cpu[:P] = @cpu[:P].set_bit(1)
		else
			@cpu[:P] = @cpu[:P].clear_bit(1)
		end

		if byte & 0x80 == 0
			@cpu[:P] = @cpu[:P].clear_bit(7)
		else
			@cpu[:P] = @cpu[:P].set_bit(7)
		end
	end

	def sign_zero_set(byte) #Only sets flag ( in case of load or store instruction )
		if byte==0
			@cpu[:P] = @cpu[:P].set_bit(1)
		else 
			@cpu[:P] = @cpu[:P].clear_bit(1)
		end

		if byte & 0x80 != 0
			@cpu[:P] = @cpu[:P].set_bit(7)
		end
	end

	def sign_zero_set_switch(byte) # S_z_set, mais avec le petit bonus "Carry" pour les opcodes de switch !
		if byte==0
			@cpu[:P] = @cpu[:P].set_bit(1)
		end
		if byte & 0x80 != 0
			@cpu[:P] = @cpu[:P].set_bit(7)
			@cpu[:P] = @cpu[:P].set_bit(0) #set carry
		end
		@cpu[:P] = @cpu[:P].clear_bit(0) if byte & 0x80 == 0 #clear carry
	end


	def read(adresse)

		case adresse
			when 0x2007
				@ppu.registers[0x2000].bit?(2) ==1 ? @pointeur_2006+=32 : @pointeur_2006+=1
			when 0x2004
				@ppu.registers[0x2003] =  @ppu.registers[0x2003].int8_plus(1)
		end

		if Registers.include?(adresse)
			return @ppu.registers[adresse]
		else
			return @ram[adresse]
		end
	end


	def write(adresse,value)
	
		case adresse 
			when 0x2007
				@ppu.ppu[@pointeur_2006] = value
			
				@ppu.registers[0x2000].bit?(2) ==1 ? @pointeur_2006+=32 : @pointeur_2006+=1
		
			when 0x2006
				if @pointeur_2006==nil
					@pointeur_2006 = value
				elsif @pointeur_2006 <= 0xFF
					@pointeur_2006 = value + (@pointeur_2006 *256) ###CA VIENDRAIT DE Là 
				elsif @pointeur_2006 > 0xFF
					@pointeur_2006 = value
				end
				until @pointeur_2006.between?(0,0x3FFF)
					@pointeur_2006 -= 0x4000
				end


			when 0x2004
				@OAM[@ppu.registers[0x2003]] = value
				@ppu.registers[0x2003] = @ppu.registers[0x2003].int8_plus(1)

			when 0x4014
				@OAM = @ram[value*0x100..(value*0x100)+0xFF]
		end
	
		if Registers.include?(adresse)
			@ppu.registers[adresse] = value
			return @ppu.registers[adresse]
		else
			@ram[adresse] = value
			return @ram[adresse]
		end

	end


end


	
#attr_accessor #googler ça
