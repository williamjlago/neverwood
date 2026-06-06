#fog.gd
extends TileMapLayer

@export var tilemap_path := NodePath("../WorldTileLayer")
@export var player_path := NodePath("../Player")
@export var vision_radius := 7

@onready var tilemap: TileMapLayer = get_node(tilemap_path)
@onready var player: Node2D = get_node(player_path)

const FOG_FULL   : Vector2i = Vector2i(0, 0)  # full opaque fog tile (0,0)
const FOG_MEMORY : Vector2i = Vector2i(0, 1)  # memory (semi) fog tile (0,1)
const FOG_CLEAR  : Vector2i = Vector2i(0, 2)  # clear/transparent tile (0,2)

var visible_tiles := {}
var explored_tiles := {}

func _ready() -> void:
	# Initialize whole fog layer to full fog
	var used = tilemap.get_used_rect()
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var coords = Vector2i(x, y)
			# set_cell(coords, source_id, atlas_coords, alternative_tile)
			# source_id is 0 if you only have one atlas in the tileset.
			set_cell(coords, 0, FOG_FULL, 0)
	update_fov()

func update_fov() -> void:
	visible_tiles.clear()
	
	var player_local = tilemap.to_local(player.global_position)
	var player_tile:Vector2i = tilemap.local_to_map(player_local)
	visible_tiles[player_tile] = true
	explored_tiles[player_tile] = true
	
	# run shadowcasting for each octant
	for octant in range(8):
		_cast_light(player_tile, 1, 1.0, 0.0, (vision_radius+1), octant)
		
	# update fog tiles
	var used = tilemap.get_used_rect()
	for x in range(used.position.x, used.end.x):
		for y in range(used.position.y, used.end.y):
			var pos = Vector2i(x,y)
			if visible_tiles.has(pos):
				set_cell(pos,0,FOG_CLEAR,0)
				explored_tiles[pos] = true
			elif explored_tiles.has(pos):
				set_cell(pos,0,FOG_MEMORY,0)
			else:
				set_cell(pos,0,FOG_FULL,0)
				
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not enemy:
			continue
		var e_local = tilemap.to_local(enemy.global_position)
		var e_tile: Vector2i = tilemap.local_to_map(e_local)
		var is_vis: bool = visible_tiles.has(e_tile)
		enemy.update_visibility(is_vis)

func _cast_light(origin: Vector2i, row: int, start_slope: float, end_slope: float, radius: int, octant:int) -> void:
	if start_slope < end_slope:
		return
	var radius_sq = radius*radius
	var blocked = false
	var new_start = start_slope
	
	for distance in range(row, radius+1):
		var dx = -distance
		var dy = -distance
		while dx <= 0:
			# compute slopes for the tile's left and right edges
			var l_slope = (dx - 0.5) / (dy + 0.5)
			var r_slope = (dx + 0.5) / (dy - 0.5)
			# skip columns outside the current slope range
			if start_slope < r_slope:
				dx += 1
				continue
			elif end_slope > l_slope:
				break
			# transform to map octant
			var map_pos := origin + _transform_octant(dx, dy, octant)
			# skip positions outside the tilemap's used rect
			var used = tilemap.get_used_rect()
			if not used.has_point(map_pos):
				dx += 1
				continue
			# mark visible if within radius
			var dist_sq = dx * dx + dy * dy
			if dist_sq < radius_sq:
				visible_tiles[map_pos] = true
			var opaque = _is_opaque(map_pos)
			if blocked:
				if opaque:
					new_start = r_slope
				else:
					blocked = false
					start_slope = new_start
			elif opaque and distance < radius - 1:
				# new blocking tile; recurse for the region before it
				blocked = true
				new_start = r_slope
				_cast_light(origin, distance + 1, start_slope, l_slope, radius, octant)
			dx += 1
			
		if blocked:
			break
			
func _is_opaque(tile_pos: Vector2i) -> bool:
	var tile = tilemap.get_cell_tile_data(tile_pos)
	if not tile:
		# treat missing tiles as opaque
		return true
	return tile.get_custom_data("block_sight")
	
func _transform_octant(dx: int, dy: int, oct: int) -> Vector2i:
	match oct:
		0: return Vector2i(dx, -dy)
		1: return Vector2i(dy, -dx)
		2: return Vector2i(dy, dx)
		3: return Vector2i(dx, dy)
		4: return Vector2i(-dx, dy)
		5: return Vector2i(-dy, dx)
		6: return Vector2i(-dy, -dx)
		7: return Vector2i(-dx, -dy)
	return Vector2i.ZERO
