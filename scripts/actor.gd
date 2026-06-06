class_name Actor extends AnimatedSprite2D

@export var speeds = {
	"move": 1.0,
	"attack": 1.0,
	"cast": 1.0,
	"global": 1.0
}

@export var max_health: float = 1
@onready var health: float = max_health
@onready var level: int = 1
@onready var attack_power: float = 0
@onready var accuracy: float = 0
@onready var spell_accuracy: float = 0
@onready var dodge: float = 0
@onready var protection: int = 0
@export var melee_damage: float = 0
@export var health_regen: float = 1.0
var dead: bool = false

var energy: float = 0
var energy_per_tick: float = 0.01
var strength: int = 10
var dexterity: int = 10
var vitality: int = 10
var intellect: int = 10
var wisdom: int = 10
var luck: int = 10

func can_act() -> bool:
	return energy >= 1.0
	
func spend_energy(action_type: String) -> void:
	energy -= 1.0
	if action_type in speeds:
		var speed = speeds[action_type]
		energy_per_tick = 0.01 * speed
	energy_per_tick = energy_per_tick * speeds["global"]

func energy_tick() -> void:
	energy += energy_per_tick

func health_regen_tick() -> void:
	if health < max_health:
		health += health_regen

func update_visibility(vis: bool) -> void:
	visible = vis
	
func update_position():
	return
	
func modify_health(value: float) -> void:
	health += value
	if health <= 0:
		destroy()
	if health > max_health:
		health = max_health
		
func melee_attack(target: Actor) -> void:
	target.health -= melee_damage
	return

func pass_turn() -> void:
	energy -= 1.0
	return

func destroy():
	if is_in_group("enemies"):
		remove_from_group("enemies")
	TurnManager.unregister_actor(self)
	queue_free()

func _process(_delta):
	if health <= 0:
		dead = true
	
	if dead:
		if is_in_group("enemies"):
			destroy()
		else:
			visible = false
