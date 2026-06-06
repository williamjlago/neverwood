class_name Player extends Actor

@onready var tilemap: TileMapLayer = get_node(NodePath("../WorldTileLayer"))
@onready var fog: TileMapLayer = get_node(NodePath("../FogTileLayer"))
@onready var light = $PointLight2D
var pathing_speed = 300.0
var astar = AStarGrid2D.new()
var used_rect
var world_path: Array[Vector2]
var target: Vector2 = Vector2.ZERO
var moving = false
var resting = false
var experience = 0
var exp_to_next_level = 50
var held_keys := {}

func _ready():
	TurnManager.register_actor(self, true)
	_setup_astar()
	
func _setup_astar():
	used_rect = tilemap.get_used_rect()
	astar.region = Rect2i(used_rect.position, used_rect.size)
	astar.cell_size = tilemap.tile_set.tile_size
	astar.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ALWAYS
	astar.update()
	for x in range(used_rect.position.x, used_rect.end.x):
		for y in range(used_rect.position.y, used_rect.end.y):
			var coords = Vector2i(x, y)
			var data = tilemap.get_cell_tile_data(coords)
			if data:
				if data.get_custom_data("block_move"):
					astar.set_point_solid(coords, true)
				else:
					astar.set_point_solid(coords, false)
			else:
				astar.set_point_solid(coords, true)
	astar.update()

func _unhandled_input(event):
	if not can_act() or dead:
		return
	# move via mouse click
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var target_tile = tilemap.local_to_map(tilemap.to_local(get_global_mouse_position()))
		move_to_tile(target_tile)
		return
	# move via WASD
	if event is InputEventKey and event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
		if event.pressed:
			held_keys[event.keycode] = true
		else:
			if not moving:
				_handle_key_move(held_keys)
			held_keys.erase(event.keycode)
	
	if event is InputEventKey and event.keycode in [KEY_SPACE]:
		if event.pressed:
			held_keys[event.keycode] = true
		else:
			if not moving:
				pass_turn()
			held_keys.erase(event.keycode)
	
	if event is InputEventKey and event.keycode in [KEY_R]:
		if event.pressed:
			held_keys[event.keycode] = true
		else:
			if not moving:
				resting = true
			held_keys.erase(event.keycode)

func _handle_key_move(keys: Dictionary):
	if keys.is_empty():
		return
	var move_dir = Vector2i.ZERO
	
	if KEY_W in keys:
		move_dir.y -= 1
	if KEY_S in keys:
		move_dir.y += 1
	if KEY_A in keys:
		move_dir.x -= 1
	if KEY_D in keys:
		move_dir.x += 1
		
	if move_dir == Vector2i.ZERO:
		return
		
	var target_tile = tilemap.local_to_map(tilemap.to_local(global_position)) + move_dir
	move_to_tile(target_tile)
	
func move_to_tile(target_tile: Vector2i) -> void:
	var player_tile = tilemap.local_to_map(tilemap.to_local(global_position))
	if not astar.is_in_boundsv(target_tile) or astar.is_point_solid(target_tile):
		#print("Move failed: impassible tile.")
		return
	if tilemap.actor_at(target_tile):
		for actor in TurnManager.actors:
			# check coords against all actors to find the occupying one
			if tilemap.local_to_map(tilemap.to_local(actor.global_position)) == target_tile:
					# found the right actor
					if actor in get_tree().get_nodes_in_group("enemies"):
						# if it's an enemy, attempt to attack or move into range to attack
						var enemy_tile = tilemap.local_to_map(tilemap.to_local(actor.global_position))
						if abs(player_tile.x - enemy_tile.x) <= 1 and abs(player_tile.y - enemy_tile.y) <= 1:
							melee_attack(actor)
							spend_energy("attack")
							return
						else:
							print("not close enough, path to enemy")
					else:
						# NYI: if not an enemy, attempt to interact or move into range to interact
						return
		
	var path: PackedVector2Array = get_path_avoiding_actors(player_tile, target_tile, self)
	if path.is_empty():
		#print("Move failed: AStar returned empty path.")
		return
		
	var tile_size = Vector2(tilemap.tile_set.tile_size)
	var path_tiles := []
	for p in path:
		var pvec = Vector2(p)
		var tx := int(round(pvec.x/tile_size.x))
		var ty := int(round(pvec.y/tile_size.y))
		var tile = Vector2i(tx, ty)
		path_tiles.append(tile)
	
	world_path.clear()
	var last_world = Vector2.ZERO
	var last_world_set = false
	for tile in path_tiles:
		var world_pos = tilemap.to_global(tilemap.map_to_local(tile)) - tile_size / 2
		if (not last_world_set) or world_pos.distance_squared_to(last_world) > 0.0001:
			world_path.append(world_pos)
			last_world = world_pos
			last_world_set = true
		
	if world_path.is_empty():
		#print("World path empty after conversion; aborting.")
		return
	
	if global_position.distance_to(world_path[0]) < 1.0:
		world_path.pop_front()
	
	if not world_path.is_empty():
		target = world_path[0]
		moving = true
	else:
		moving = false

func check_enemies() -> void:
	if world_path.size() > 0 or resting:
		var enemies_visible = false
		if fog:
			for e in get_tree().get_nodes_in_group("enemies"):
				var e_tile: Vector2i = tilemap.local_to_map(tilemap.to_local(e.global_position))
				if fog.visible_tiles.has(e_tile):
					enemies_visible = true
					break
			if enemies_visible:
				world_path.clear()
				resting = false
				return

func get_path_avoiding_actors(from_tile: Vector2i, to_tile: Vector2i, ignore_actor: Actor = null, ignore_target: Actor = null) -> PackedVector2Array:
	# Temporarily mark all actor positions as solid
	var actor_positions := []
	for actor in TurnManager.actors:
		if actor == ignore_actor or actor == ignore_target or actor.dead:
			continue
		var actor_tile = tilemap.local_to_map(tilemap.to_local(actor.global_position))
		if astar.is_in_boundsv(actor_tile) and not astar.is_point_solid(actor_tile):
			actor_positions.append(actor_tile)
			astar.set_point_solid(actor_tile, true)
	astar.update()
	
	# Try to get a direct path first
	var path: PackedVector2Array = astar.get_point_path(from_tile, to_tile)
	
	# If no direct path exists, find the closest reachable point
	if path.is_empty():
		var id_path: Array[Vector2i] = astar.get_id_path(from_tile, to_tile)
		if not id_path.is_empty():
			# Convert tile coordinates to world coordinates
			path = PackedVector2Array()
			for tile_pos in id_path:
				var world_pos = astar.get_point_position(tile_pos)
				path.append(world_pos)
	
	# Unmark actor positions
	for pos in actor_positions:
		astar.set_point_solid(pos, false)
	astar.update()
	
	return path

func _physics_process(delta) -> void:
	# update damage based on stats/gear; placeholder for now
	melee_damage = 5
	
	if world_path.is_empty():
		if moving:
			print("World path empty, stopping movement.")
		moving = false
		return
	
	if target == Vector2.ZERO and world_path.size() > 0:
		target = world_path[0]
		
	var dir: Vector2 = target - global_position
	var step: Vector2 = dir.normalized() * pathing_speed * delta
	var dist: float = dir.length()
	if step.length() >= dist:
		global_position = target
		
		if fog:
			fog.update_fov()
		
		if not world_path.is_empty():
			world_path.pop_front()
		target = world_path[0] if world_path.size() > 0 else Vector2.ZERO
		if world_path.size() > 0 and world_path[0] != Vector2.ZERO:
			target = world_path[0]
			moving = true
		else:
			world_path.clear()
			moving = false
		# print("Moved to [%s, %s]" % [tilemap.local_to_map(tilemap.to_local(global_position)).x, tilemap.local_to_map(tilemap.to_local(global_position)).y])
		spend_energy("move")
		check_enemies()

		if world_path.is_empty():
			moving = false
	else:
		global_position += step
		
