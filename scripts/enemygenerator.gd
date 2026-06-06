class_name EnemyGenerator extends Node

@onready var tilemap: TileMapLayer = get_parent()
const enemy_scene: PackedScene = preload("res://scenes/enemy.tscn")

func place_enemies(num_enemies: int):
	var enemies_placed = 0
	var used_rect = tilemap.get_used_rect()
	var min_x = used_rect.position.x
	var min_y = used_rect.position.y
	var max_x = used_rect.position.x + used_rect.size.x - 1
	var max_y = used_rect.position.y + used_rect.size.y - 1
	
	while enemies_placed < num_enemies:
		var place_x = randi_range(min_x, max_x)
		var place_y = randi_range(min_y, max_y)
		var place_tile = Vector2i(place_x, place_y)
		var data = tilemap.get_cell_tile_data(place_tile)
		if not data:
			continue
		if data.get_custom_data("block_move") == true or tilemap.actor_at(place_tile):
			continue

		var enemy_to_place: Enemy = new_enemy(place_tile, choose_enemy())
		get_tree().current_scene.add_child.call_deferred(enemy_to_place)
		enemies_placed += 1

func new_enemy(pos: Vector2i, id: int) -> Enemy:
	var enemy: Enemy = enemy_scene.instantiate()
	enemy.init_pos = tilemap.to_global(tilemap.map_to_local(pos))
	enemy.init_pos.x -= 8
	enemy.init_pos.y -= 8
	enemy.enemy_id = id
	return enemy
	
func choose_enemy() -> int:
	# NYI: choose an enemy id to place from a map-specific table.
	var map_enemies = [1, 3]
	var rand = randi_range(0,1)
	var id = map_enemies[rand]
	return id
