extends Node2D

var powerup = null : set = set_powerup

func _ready():
	pass

func _process(_delta):
	pass

func set_powerup(new_powerup):
	powerup = new_powerup
	if new_powerup == null:
		$Sprite2D.texture = null
	else:
		$Sprite2D.texture = load("res://assets/" + powerup + ".png")

func on_use_powerup(reference):
	if powerup != null:
		if powerup == "teleport":
			reference.spawn()
		powerup = null
