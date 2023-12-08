extends Resource
class_name Upgrade

var text: String
var callback: Callable
var prototype: ActionPrototype

func _init(text_: String = "", callback_: Callable = func(): return null, action_prototype: ActionPrototype = null):
	text = text_
	callback = callback_
	prototype = action_prototype

func reset():
	text = ""
	callback = func(): return null
	prototype = null

func set_upgrade(other: Upgrade):
	text = other.text
	callback = other.callback
	prototype = other.prototype

func apply(map: Map, action_factory: ActionFactory):
	callback.call(map, action_factory, prototype)
	
	if prototype != null:
		prototype.weight += 1
		prototype.level += 1
