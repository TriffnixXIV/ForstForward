extends Control
class_name Stats

var stat_label_settings = preload("res://Text/StatLabelSettings.tres")

enum Type {Horst, Forst}

func add_stat(type: Type, text: String):
	var target = $Horst if type == Type.Horst else $Forst
	
	var label = Label.new()
	label.text = text
	label.label_settings = stat_label_settings
	target.add_child(label)

func update_stat(type: Type, index: int, text: String):
	var target = $Horst if type == Type.Horst else $Forst
	
	while index > target.get_child_count() - 1:
		add_stat(type, "")
	target.get_child(index).text = text

func update_stats(type: Type, stat_array: Array[String]):
	var target = $Horst if type == Type.Horst else $Forst
	
	for i in len(stat_array):
		target.get_child(i + 1).text = stat_array[i]
