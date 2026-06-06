class_name Enemy extends Actor

@onready var player = get_node("../Player")
@onready var tilemap = get_node("../WorldTileLayer")
@onready var fog: TileMapLayer = get_node(NodePath("../FogTileLayer"))
@onready var astar: AStarGrid2D = player.astar
@export var enemy_id: int = 0
@export var init_pos: Vector2i
var awake: bool = false
var last_known_player_tile: Vector2i = Vector2i.ZERO

func _ready():
	set_enemy_by_id()
	TurnManager.register_actor(self, false)
	add_to_group("enemies")
	global_position = init_pos
	
func move_to_tile(new_tile: Vector2i) -> void:
	if tilemap.actor_at(new_tile):
		return
	var adj_pos = tilemap.to_global(tilemap.map_to_local(new_tile))
	adj_pos.x -= 8
	adj_pos.y -= 8
	global_position = adj_pos
	if new_tile not in fog.visible_tiles:
		update_visibility(false)
	else:
		update_visibility(true)
	
func wander(move_chance:int = 70) -> void:
	var move_dest = Vector2i.ZERO
	var roll = randi_range(1,100)
	if roll > move_chance:
		spend_energy("action")
		return
		
	var ready_to_move = false
	var move = Vector2i.ZERO
	var move_dir:int = 0
	while not ready_to_move:
		move = Vector2i.ZERO
		move_dir = randi_range(0,7)
		match move_dir:
			0: # move up
				move.y = -1
			1: # move up-right
				move.x = 1
				move.y = -1
			2: # move right
				move.x = 1
			3: # move down-right
				move.x = 1
				move.y = 1
			4: # move down
				move.y = 1
			5: # move down-left
				move.x = -1
				move.y = 1
			6: # move left
				move.x = -1
			7: # move up-left
				move.x = -1
				move.y = -1
				
		move_dest = tilemap.local_to_map(tilemap.to_local(global_position)) + move
		var tile_data = tilemap.get_cell_tile_data(move_dest)
		if tile_data:
			var solid = tile_data.get_custom_data("block_move")
			if not solid:
				ready_to_move = true
	move_to_tile(move_dest)	
	spend_energy("move")
	return

func update_visibility(vis: bool) -> void:
	visible = vis
	
func can_see_player() -> bool:
	var current_tile = tilemap.local_to_map(tilemap.to_local(global_position))
	var can_see = current_tile in fog.visible_tiles	
	return can_see

func see_player() -> void:
	last_known_player_tile = tilemap.local_to_map(tilemap.to_local(player.global_position))
	
func chase_melee(target: Actor):
	# chase the player and attempt to melee attack
	var self_tile = tilemap.local_to_map(tilemap.to_local(global_position))
	var target_tile = tilemap.local_to_map(tilemap.to_local(target.global_position))
	if abs(self_tile.x - target_tile.x) <= 1 and abs(self_tile.y - target_tile.y) <= 1:	
		# close enough to melee attack
		print("An enemy has attacked you!")
		melee_attack(target)
		spend_energy("attack")
	else:
		# not close enough; path to target
		print("An enemy is chasing you")
		path_toward(self_tile, target_tile, target)
		spend_energy("move")

func set_enemy_by_id() -> void:
	# check enemy ID and change sprite/attributes accordingly
	match enemy_id:
		1:
			name = "Skeleton Warrior"
			max_health = 15
			health = 15
			melee_damage = 5
			health_regen = 0
			animation = &"skelwar"
		2:
			name = "Skeleton King"
			max_health = 50
			health = 50
			melee_damage = 10
			health_regen = 0
			animation = &"skelking"
		3:
			name = "Spider"
			max_health = 12
			melee_damage = 7
			health_regen = 1
			animation = &"spider"
	return
	
func go_to_last_known_player_pos():
	var tile_pos = tilemap.local_to_map(tilemap.to_local(global_position))
	if last_known_player_tile != Vector2i.ZERO and tile_pos != last_known_player_tile:
		path_toward(tile_pos, last_known_player_tile)
		spend_energy("move")
	else:
		last_known_player_tile = Vector2i.ZERO
		wander()
		

func path_toward(self_tile: Vector2i, target_tile: Vector2i, target_actor: Actor = null):
	var path: PackedVector2Array = player.get_path_avoiding_actors(self_tile, target_tile, self, target_actor)
	
	if path.is_empty():
		print("Enemy pathfinding failed: empty path from ", self_tile, " to ", target_tile)
		return
	
	var tile_size = Vector2(tilemap.tile_set.tile_size)
	var path_tiles := []
	for p in path:
		var pvec = Vector2(p)
		var tx := int(round(pvec.x/tile_size.x))
		var ty := int(round(pvec.y/tile_size.y))
		var tile = Vector2i(tx, ty)
		path_tiles.append(tile)
		if path_tiles.size() > 1:
			break
	
	print("Enemy path_tiles: ", path_tiles)
	
	if path_tiles.size() > 1:
		print("Checking tile: ", path_tiles[1], " Actor present: ", tilemap.actor_at(path_tiles[1]))
		if not tilemap.actor_at(path_tiles[1]):
			print("Moving enemy to: ", path_tiles[1])
			move_to_tile(path_tiles[1])
		else:
			print("Tile blocked by actor, cannot move")
	else:
		print("Path only has ", path_tiles.size(), " tiles, cannot move")
	return
	

func _exit_tree():
	# Clean up registration if enemy is destroyed
	remove_from_group("enemies")
