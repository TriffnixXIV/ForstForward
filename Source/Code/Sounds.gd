extends Node

var move_sounds = [
	preload("res://Sounds/VillagerAdvancementSounds/Step1.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Step2.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Step3.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Step4.wav")
]
var chop_sounds = [
	preload("res://Sounds/VillagerAdvancementSounds/Chop1.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Chop2.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Chop3.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Chop4.wav")
]
var build_sounds = [
	preload("res://Sounds/VillagerAdvancementSounds/Build1.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Build2.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Build3.wav"),
	preload("res://Sounds/VillagerAdvancementSounds/Build4.wav")
]

func move():
	$Move.stream = move_sounds[randi_range(0, len(move_sounds) - 1)]
	$Move.play()

func chop():
	$Chop.stream = chop_sounds[randi_range(0, len(chop_sounds) - 1)]
	$Chop.play()

func build():
	$Build.stream = build_sounds[randi_range(0, len(build_sounds) - 1)]
	$Build.play()

func grow():
	$Grow.play()
