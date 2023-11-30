extends Node

var upgrade_sounds = [
	preload("res://Sounds/CrystalSounds/Upgrade1.wav"),
	preload("res://Sounds/CrystalSounds/Upgrade2.wav"),
	preload("res://Sounds/CrystalSounds/Upgrade3.wav")
]

func upgrade():
	$Upgrade.stream = upgrade_sounds[randi_range(0, len(upgrade_sounds) - 1)]
	$Upgrade.play()
