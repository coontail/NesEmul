class Integer
	def int8_plus(integer)
		((self+integer).abs)%256
	end
	
	def int8_minus(integer)
		if (self-integer)<0
			(self-integer)+256
		else
			(self-integer)
		end
	end

end




class Fixnum
	def bit?(bit)
		if bit == 7
			value = 0 if self & 128 == 0
			value = 1 if self & 128 != 0
		elsif bit == 6
			value =  0 if self & 64 == 0
			value =  1 if self & 64 != 0
		elsif bit == 5
			value =  0 if self & 32 == 0
			value =  1 if self & 32 != 0
		elsif bit == 4
			value = 0 if self & 16 == 0
			value = 1 if self & 16 != 0
		elsif bit == 3
			value =  0 if self & 8 == 0
			value =  1 if self & 8 != 0
		elsif bit == 2
			value = 0 if self & 4 == 0
			value =  1 if self & 4 != 0
		elsif bit == 1
			value =  0 if self & 2 == 0
			value =  1 if self & 2 != 0
		elsif bit == 0
			value =  0 if self & 1 == 0
			value = 1 if self & 1 != 0
		end

		return value
	end
	
	def set_bit(bit)
		self | case bit
			when 7 then 128
			when 6 then 64
			when 5 then 32
			when 4 then 16
			when 3 then 8
			when 2 then 4
			when 1 then 2
			when 0 then 1
		end
	end

	def clear_bit(bit)
		self & case bit
			when 7 then 127
			when 6 then 191
			when 5 then 223
			when 4 then 239
			when 3 then 247
			when 2 then 251
			when 1 then 253
			when 0 then 254
		end
	end	
end


def signed(int)
	table_conversion = Array(0..128) + Array(-127..-1)
	return table_conversion[int]
end

