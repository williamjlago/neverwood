class_name Skill extends Node

var description: String = ""
var stamina_cost: int = 0
var mana_cost: int = 0
var cooldown: int = 0
var action_type: String = ""
var skill_level: int = 1

func _init(skname: String, desc: String, scost: int, mcost: int, cd: int, atype: String, lvl: int):
	name = skname
	description = desc
	stamina_cost = scost
	mana_cost = mcost
	cooldown = cd
	action_type = atype
	skill_level = lvl
	
