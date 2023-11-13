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

enum TileType {plains, growth, forest, build_site, house}

var save_filepath_start = "user://save/"
var save_data = SaveData.new()

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

func cell_is_type(cell_position, type):
	match type:
		TileType.plains:		return is_plains(cell_position)
		TileType.growth:		return is_growth(cell_position)
		TileType.forest:		return is_forest(cell_position)
		TileType.build_site:	return is_build_site(cell_position)
		TileType.house:			return is_house(cell_position)

func is_valid_tile(cell_position: Vector2i):
	return get_cell_source_id(0, cell_position) != -1

func is_identical_tile(cell_position: Vector2i, source_id: int, atlas_coords: Vector2i):
	var part1 = get_cell_source_id(0, cell_position) == source_id
	var part2 = get_cell_atlas_coords(0, cell_position) == atlas_coords
	return part1 and part2

func is_plains(cell_position: Vector2i):
	return get_cell_source_id(0, cell_position) == TileType.plains

func is_growth(cell_position: Vector2i):
	return get_cell_source_id(0, cell_position) == TileType.growth

func is_forest(cell_position: Vector2i):
	return get_cell_source_id(0, cell_position) == TileType.forest

func is_build_site(cell_position: Vector2i):
	return get_cell_source_id(0, cell_position) == TileType.build_site

func is_house(cell_position: Vector2i):
	return get_cell_source_id(0, cell_position) == TileType.house
