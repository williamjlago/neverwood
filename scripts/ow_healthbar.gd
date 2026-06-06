extends TextureProgressBar

@onready var parent_actor: Actor = get_parent()
const GREEN_TEX = preload("res://assets/ui/ow_health_fill_green.png")
const YELLOW_TEX = preload("res://assets/ui/ow_health_fill_yellow.png")
const RED_TEX = preload("res://assets/ui/ow_health_fill_red.png")

func _process(_delta):
	max_value = parent_actor.max_health
	value = parent_actor.health
	
	if value < max_value:
		visible = true
	else:
		visible = false
		
	if value / max_value > 0.66:
		texture_progress = GREEN_TEX
	elif value / max_value > 0.33:
		texture_progress = YELLOW_TEX
	else:
		texture_progress = RED_TEX
	
