extends Node2D

var powerup = null : set = set_powerup

var lock_use_powerup = false

func _ready():
	pass

func _process(_delta):
	pass

func set_powerup(new_powerup):
	lock_use_powerup = false
	powerup = new_powerup
	$Sprite2D.modulate = Color(1, 1, 1, 1)
	if new_powerup == null:
		$Sprite2D.texture = null
	else:
		$Sprite2D.texture = load("res://assets/" + powerup + ".png")
		$AnimationPlayer.play("spawn")

func on_use_powerup(reference):
	var powerup_used = false
	if powerup != null and not lock_use_powerup:
		if powerup == "expand":
			powerup_used = reference.expand()
		elif powerup == "fast":
			powerup_used = reference.fast()
		elif powerup == "shield":
			powerup_used = reference.shield()
		elif powerup == "comet":
			powerup_used = reference.comet()
		elif powerup == "vacuum":
			powerup_used = reference.vacuum()
		elif powerup == "teleport":
			powerup_used = reference.spawn(true)
		elif powerup == "bomb":
			powerup_used = reference.bomb()

	if powerup_used:
		lock_use_powerup = true
		$AnimationPlayer.play("deplete")
	else:
		reference.whiff_powerup()


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "deplete":
		powerup = null
