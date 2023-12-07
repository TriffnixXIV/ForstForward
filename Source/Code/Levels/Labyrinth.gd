extends Level

func generate():
	_ready()
	for x in width:
		for y in height:
			set_plains(Vector2i(x, y))
			set_forest(Vector2i(x, y))
	
	var cell_centers = []
	for x in width:
		if x % 4 == 2:
			var y = 0
			var steps = [3, 3, 3, 4, 4]
			steps.shuffle()
			steps += [2]
			while steps != []:
				y += steps.pop_back()
				cell_centers.append(Vector2i(x, y))
				set_empty(Vector2i(x, y))
				for diff in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(1, 1), Vector2i(1, -1)]:
					set_empty(Vector2i(x, y) + diff)
					set_empty(Vector2i(x, y) - diff)
	
	cell_centers.shuffle()
	var count = 6
	for cell in cell_centers:
		if cell.x not in [2, width - 3]:
			if count > 4:
				set_house(cell)
			else:
				set_build_site(cell, 5)
			count -= 1
			if count == 0:
				break
	
	cell_centers.shuffle()
	var left_done = false
	var right_done = false
	for cell in cell_centers:
		if not left_done and cell.x == 2 and min(cell.y, height - cell.y) > 4:
			set_house(Vector2i(0, cell.y))
			set_house(Vector2i(1, cell.y))
			set_empty(Vector2i(0, cell.y - 1))
			set_empty(Vector2i(0, cell.y + 1))
			left_done = true
		if not right_done and cell.x == width - 3 and min(cell.y, height - cell.y) > 4:
			set_house(Vector2i(width - 1, cell.y))
			set_house(Vector2i(width - 2, cell.y))
			set_empty(Vector2i(width - 1, cell.y - 1))
			set_empty(Vector2i(width - 1, cell.y + 1))
			right_done = true
	
	var ys = range(height)
	for x in width:
		if x % 4 == 0 and x not in [0, width - 1]:
			ys.shuffle()
			count = 2
			for y in ys:
				var valid = true
				for diff in [-1, 0, 1]:
					valid = valid and not is_valid_tile(Vector2i(x - 1, y + diff), 1)
					valid = valid and is_forest(Vector2i(x, y + diff))
					valid = valid and not is_valid_tile(Vector2i(x + 1, y + diff), 1)
				for diff in [-2, 2]:
					valid = valid and is_forest(Vector2i(x, y + diff)) 
				valid = valid and (
					is_forest(Vector2i(x - 1, y + 2)) or is_forest(Vector2i(x + 1, y + 2)) or
					is_forest(Vector2i(x - 1, y - 2)) or is_forest(Vector2i(x + 1, y - 2)))
				if valid:
					set_empty(Vector2i(x, y))
					set_empty(Vector2i(x, y - 1))
					set_empty(Vector2i(x, y + 1))
					count -= 1
					if count == 0:
						break
