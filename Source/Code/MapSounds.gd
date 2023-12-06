extends Node

var crystal_crack_sounds = [
	preload("res://Sounds/CrystalSounds/Crack1.wav"),
	preload("res://Sounds/CrystalSounds/Crack2.wav"),
	preload("res://Sounds/CrystalSounds/Crack3.wav")
]

func crystal_crack():
	$CrystalCrack.stream = crystal_crack_sounds.pick_random()
	$CrystalCrack.play()
