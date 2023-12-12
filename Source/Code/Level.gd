extends TileMap
class_name Level

@export var level_name: String = "Level Name"
@export var level_id: String = "LevelName"

var width = 0
var height = 0

@export var random_starting_crystals: int
@export var base_life_crystals: int
@export var base_growth_crystals: int
@export var base_weather_crystals: int

var save_filepath_start = "user://save/"
var save_data = SaveData.new()

var atlas_coords = {
	"plains":	Vector2i(0, 0),
	"forest":	Vector2i(10, 0),
	"sand":		Vector2i(0, 1),
	"house":	Vector2i(10, 1),
	"water":	Vector2i(0, 2)
}

func _ready():
	while is_valid_tile(Vector2i(width, 0)):
		width += 1
	while is_valid_tile(Vector2i(0, height)):
		height += 1
	
	# verify file location
	DirAccess.make_dir_absolute(save_filepath_start)

func load_save_data():
	var filepath = save_filepath_start + level_id + "SaveData.tres"
	if ResourceLoader.exists(filepath):
		var loaded = ResourceLoader.load(filepath)
		if loaded != null:
			save_data = loaded.duplicate(true)
	else:
		save_player_data()

func save_player_data():
	var filepath = save_filepath_start + level_id + "SaveData.tres"
	ResourceSaver.save(save_data, filepath)

# cell type stuff

func set_plains(cell_position: Vector2i):
	set_cell(0, cell_position, 0, Vector2i(0, 0))

func set_sand(cell_position: Vector2i):
	set_cell(0, cell_position, 0, Vector2i(0, 1))
	
func set_water(cell_position: Vector2i):
	set_cell(0, cell_position, 0, Vector2i(0, 2))
	
func set_growth(cell_position: Vector2i, amount: int):
	set_cell(1, cell_position, 0, Vector2i(amount, 0))

func set_forest(cell_position: Vector2i):
	set_cell(1, cell_position, 0, Vector2i(10, 0))

func set_build_site(cell_position: Vector2i, progress: int):
	set_cell(1, cell_position, 0, Vector2i(progress, 1))

func set_house(cell_position: Vector2i):
	set_cell(1, cell_position, 0, Vector2i(10, 1))

func set_empty(cell_position: Vector2i):
	set_cell(1, cell_position)

func is_valid_tile(cell_position: Vector2i, layer: int = 0, size: int = 1):
	if size == 1:
		return get_cell_source_id(layer, cell_position) != -1
	else:
		for x in size:
			for y in size:
				var diff = Vector2i(x, y)
				if not is_valid_tile(cell_position + diff):
					return false
		return true

func is_empty(cell_position: Vector2i, layer: int = 1):
	return get_cell_source_id(layer, cell_position) == -1

func is_plains(cell_position: Vector2i):
	return get_cell_atlas_coords(0, cell_position) == atlas_coords["plains"]
	
func is_sand(cell_position: Vector2i):
	return get_cell_atlas_coords(0, cell_position) == atlas_coords["sand"]
	
func is_water(cell_position: Vector2i):
	return get_cell_atlas_coords(0, cell_position) == atlas_coords["water"]

func is_growth(cell_position: Vector2i):
	var coords = get_cell_atlas_coords(1, cell_position)
	return coords.y == 0 and coords.x > 0 and coords.x < 10

func is_forest(cell_position: Vector2i):
	return get_cell_atlas_coords(1, cell_position) == atlas_coords["forest"]

func is_build_site(cell_position: Vector2i):
	var coords = get_cell_atlas_coords(1, cell_position)
	return coords.y == 1 and coords.x > 0 and coords.x < 10

func is_house(cell_position: Vector2i):
	return get_cell_atlas_coords(1, cell_position) == atlas_coords["house"]

func is_identical_tile(cell_position: Vector2i, layer: int, source_id: int, atlas_coords_: Vector2i):
	var part1 = get_cell_source_id(layer, cell_position) == source_id
	var part2 = get_cell_atlas_coords(layer, cell_position) == atlas_coords_
	return part1 and part2

func is_growable(cell_position: Vector2i):
	return is_valid_tile(cell_position) and is_plains(cell_position)

func get_growable_amount(cell_position: Vector2i):
	if is_growable(cell_position):
		return get_building_progress(cell_position) + 10 - get_yield(cell_position)
	else:
		return 0

func get_yield(cell_position: Vector2i):
	if is_forest(cell_position):
		return 10
	elif is_growth(cell_position):
		return get_cell_atlas_coords(1, cell_position).x
	else:
		return 0

func is_buildable(cell_position: Vector2i):
	return is_valid_tile(cell_position) and not is_water(cell_position)

func get_building_progress(cell_position: Vector2i):
	if is_house(cell_position):
		return 10
	if is_build_site(cell_position):
		return get_cell_atlas_coords(1, cell_position).x
	else:
		return 0

func is_walkable(cell_position: Vector2i, size: int = 1):
	if size == 1:
		return is_valid_tile(cell_position) and not is_water(cell_position)
	else:
		for x in size:
			for y in size:
				var diff = Vector2i(x, y)
				if not is_walkable(cell_position + diff):
					return false
		return true

func is_water_level():
	var walkable_tiles = 0
	for x in width:
		for y in height:
			if is_walkable(Vector2i(x, y)):
				walkable_tiles += 1
	
	return walkable_tiles < width * height / 2.0

func generate():
	pass
