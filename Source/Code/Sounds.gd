extends Node

var move_sounds = [
	preload("res://Sounds/AdvancementSounds/Step1.wav"),
	preload("res://Sounds/AdvancementSounds/Step2.wav"),
	preload("res://Sounds/AdvancementSounds/Step3.wav"),
	preload("res://Sounds/AdvancementSounds/Step4.wav")
]
var chop_sounds = [
	preload("res://Sounds/AdvancementSounds/Chop1.wav"),
	preload("res://Sounds/AdvancementSounds/Chop2.wav"),
	preload("res://Sounds/AdvancementSounds/Chop3.wav"),
	preload("res://Sounds/AdvancementSounds/Chop4.wav")
]
var build_sounds = [
	preload("res://Sounds/AdvancementSounds/Build1.wav"),
	preload("res://Sounds/AdvancementSounds/Build2.wav"),
	preload("res://Sounds/AdvancementSounds/Build3.wav"),
	preload("res://Sounds/AdvancementSounds/Build4.wav")
]
var grow_sounds = [
	preload("res://Sounds/AdvancementSounds/Grow1.wav"),
	preload("res://Sounds/AdvancementSounds/Grow2.wav"),
	preload("res://Sounds/AdvancementSounds/Grow3.wav"),
	preload("res://Sounds/AdvancementSounds/Grow4.wav")
]
var plant_sounds = [
	preload("res://Sounds/AdvancementSounds/Plant1.wav"),
	preload("res://Sounds/AdvancementSounds/Plant2.wav"),
	preload("res://Sounds/AdvancementSounds/Plant3.wav"),
	preload("res://Sounds/AdvancementSounds/Plant4.wav")
]

func _ready():
	$Grow1.stream = grow_sounds[0]
	$Grow2.stream = grow_sounds[1]
	$Grow3.stream = grow_sounds[2]
	$Grow4.stream = grow_sounds[3]

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
	match randi_range(0, len(grow_sounds) - 1):
		0: $Grow1.play()
		1: $Grow2.play()
		2: $Grow3.play()
		3: $Grow4.play()

func plant():
	$Plant.stream = plant_sounds[randi_range(0, len(plant_sounds) - 1)]
	$Plant.play()
