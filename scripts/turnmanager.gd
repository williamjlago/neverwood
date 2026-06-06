# turnmanager.gd
extends Node

var tick: int = 0
var actors: Array = []
var player_actor: Actor = null

func register_actor(actor: Actor, is_player: bool=false) -> void:
	if actor in actors:
		return
	actors.append(actor)
	if is_player:
		player_actor = actor

func unregister_actor(actor: Actor) -> void:
	if actor in actors:
		actors.erase(actor)
	if actor == player_actor:
		player_actor = null

func process_enemy_turn(enemy: Actor) -> void:
	enemy.astar = player_actor.astar
	if enemy.can_see_player() and not enemy.awake:
		enemy.awake = true
		print("enemy is now awake")
	if not enemy.awake:
		enemy.energy -= 1
		return
		
	if enemy.can_see_player():
		enemy.see_player()
		print("enemy updates player's last known position...")
		enemy.chase_melee(player_actor)
		return
	else:
		enemy.go_to_last_known_player_pos()
		print("enemy can't see player, moving to last known position")
	return
	
""" Core loop: run ticks as fast as possible until it's the player's turn
Queue any enemy actions that happen in the meantime, and execute them before 
the player can act """

func _process(_delta: float) -> void:
	if not player_actor or player_actor.dead:
		return
		
	# If player is ready, execute any queued enemy actions and stop ticking
	if player_actor.can_act() and not player_actor.resting:
		return

	# otherwise run ticks
	while not player_actor.can_act() or (player_actor.resting and player_actor.health < player_actor.max_health):
		tick += 1
		if tick % 100 == 0:
			for actor in actors:
				actor.health_regen_tick()
				
		for actor in actors:
			actor.energy_tick()
			if actor != player_actor and actor.can_act():
				process_enemy_turn(actor)
			if actor == player_actor and player_actor.resting == true and player_actor.can_act():
				player_actor.energy -= 1
		if player_actor.health >= player_actor.max_health:
			player_actor.resting = false
		player_actor.check_enemies()
			
