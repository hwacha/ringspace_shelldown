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
	var powerup_used = false
	if powerup != null:
		if powerup == "teleport":
			powerup_used = reference.spawn()
		elif powerup == "expand":
			powerup_used = reference.expand()
		elif powerup == "fast":
			powerup_used = reference.fast()
		elif powerup == "comet":
			powerup_used = reference.comet()

	if powerup_used:
		powerup = null
