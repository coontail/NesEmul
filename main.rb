require "./ppu.rb"
require "./cpu.rb"
require "sdl"
require 'json'
require './opcodes.rb'
require './bitwise.rb'
#require './OAM.rb'


rom = File.open(ARGV[0]).read.bytes.to_a

$compteur_cycles = 0
$cpu = Cpu.new(rom)
$ppu = $cpu.ppu
$cpu.reset_rom


def ppu_exec(cycles)
	(3*cycles).times do
		$ppu.draw_screen
		case $compteur_cycles
			when 0 then $ppu.clear_vblank
			when 2000
				$ppu.reset_pixel
				$ppu.set_vblank
				$ppu.screen.flip
				$cpu.nmi_interrupt #if $ppu.registers[0x2000].bit?(7)==1
				$compteur_cycles = 0
		end
		$compteur_cycles += 1
	end
end

while true
	nb_args = OPCODES[$cpu.ram[$cpu.cpu[:compteur]]][:len].to_i
	$cpu.cpu[:compteur_new] += nb_args
	$cpu.send OPCODES[$cpu.ram[$cpu.cpu[:compteur]]][:opcodes].downcase, 
		$cpu.ram[$cpu.cpu[:compteur]], $cpu.ram[$cpu.cpu[:compteur]+1], $cpu.ram[$cpu.cpu[:compteur]+2]
	ppu_exec(OPCODES[$cpu.ram[$cpu.cpu[:compteur]]][:tim].to_i)
	#puts "#{$cpu.ram[$cpu.cpu[:compteur]+1]}, #{$cpu.ram[$cpu.cpu[:compteur]+2]}"
	#puts "Nom de l'instruct : #{OPCODES[$cpu.ram[$cpu.cpu[:compteur]]][:opcodes]}"
	#puts "Etat du cpu apres l'instruction #{$cpu.cpu}"
	#puts "___________________________________________________________________________________________\n"
	$cpu.cpu[:compteur] = $cpu.cpu[:compteur_new]
end

