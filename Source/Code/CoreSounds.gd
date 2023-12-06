extends Node

var upgrade_sounds = [
	preload("res://Sounds/CrystalSounds/Upgrade1.wav"),
	preload("res://Sounds/CrystalSounds/Upgrade2.wav"),
	preload("res://Sounds/CrystalSounds/Upgrade3.wav")
]
var frost_sounds = [
	preload("res://Sounds/ActionSounds/Frost1.wav"),
	preload("res://Sounds/ActionSounds/Frost2.wav"),
	preload("res://Sounds/ActionSounds/Frost3.wav"),
	preload("res://Sounds/ActionSounds/Frost4.wav")
]

func upgrade():
	$Upgrade.stream = upgrade_sounds.pick_random()
	$Upgrade.play()

func frost():
	$Frost.stream = frost_sounds.pick_random()
	$Frost.play()
