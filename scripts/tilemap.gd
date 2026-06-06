extends TileMapLayer

@onready var enemy_gen: EnemyGenerator = EnemyGenerator.new()
@export var num_enemies: int = 0

func get_actor_at(tile: Vector2i) -> Actor:
	for actor in TurnManager.actors:
		if local_to_map(to_local(actor.global_position)) == tile:
			return actor
	return null

func actor_at(tile: Vector2i) -> bool:
	for actor in TurnManager.actors:
		if local_to_map(to_local(actor.global_position)) == tile:
			return true
	return false   

func _ready():
	add_child(enemy_gen)
	enemy_gen.place_enemies(num_enemies)
