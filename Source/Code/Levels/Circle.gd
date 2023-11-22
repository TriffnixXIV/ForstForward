extends Level

func generate():
	_ready()
	
	var top_center = Vector2i(floori((width - 1) / 2.0), floori((height - 1) / 2.0))
	var bottom_center = Vector2i(floori((width - 1) / 2.0), ceili((height - 1) / 2.0))
	
	for x in width:
		for y in height:
			var cell = Vector2i(x, y)
			set_plains(cell)
			
			var top_path = cell - top_center
			var bottom_path = cell - bottom_center
			var distance = min(top_path.length(), bottom_path.length())
			
			if distance <= 1:
				set_house(cell)
			
			var inner_ring_growth = floori(20 * min(distance - 4, 6.5 - distance))
			if inner_ring_growth >= 10:
				set_forest(cell)
			elif inner_ring_growth > 0:
				set_growth(cell, inner_ring_growth)
			
			var outer_ring_growth = floori(10 * (distance - 12))
			if outer_ring_growth >= 10:
				set_forest(cell)
			elif outer_ring_growth > 0:
				set_growth(cell, outer_ring_growth)
