extends Node

var all_skills: Array[Skill] = []
var player_skills: Array[Skill] = []

func _init():
	populate_skills()
	
func populate_skills():
	
	var skill_desc = "Attack an enemy while moving up to one space forward, or up to two spaces starting at skill level 6."
	var skill = Skill.new("Advance", skill_desc, 15, 0, 0, "attack", 1)
	all_skills.append(skill)
	
	skill_desc = "Strike an enemy with a powerful blow that may stun. Higher levels have higher stun chance."
	skill = Skill.new("Power Strike", skill_desc, 15, 0, 6, "attack", 1)
	all_skills.append(skill)
