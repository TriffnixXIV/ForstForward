extends Node

var villager_move_sounds: Array
var villager_chop_sounds: Array
var villager_build_sounds: Array

func _ready():
	villager_move_sounds = [
		preload("res://Sounds/VillagerAdvancementSounds/Step1.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Step2.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Step3.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Step4.wav")
	]
	villager_chop_sounds = [
		preload("res://Sounds/VillagerAdvancementSounds/Chop1.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Chop2.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Chop3.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Chop4.wav")
	]
	villager_build_sounds = [
		preload("res://Sounds/VillagerAdvancementSounds/Build1.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Build2.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Build3.wav"),
		preload("res://Sounds/VillagerAdvancementSounds/Build4.wav")
	]

func villager_move():
	$VillagerMove.stream = villager_move_sounds[randi_range(0, len(villager_move_sounds) - 1)]
	$VillagerMove.play()

func villager_chop():
	$VillagerChop.stream = villager_chop_sounds[randi_range(0, len(villager_move_sounds) - 1)]
	$VillagerChop.play()

func villager_build():
	$VillagerBuild.stream = villager_build_sounds[randi_range(0, len(villager_move_sounds) - 1)]
	$VillagerBuild.play()
