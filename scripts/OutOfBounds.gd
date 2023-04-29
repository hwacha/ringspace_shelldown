extends Area2D


func _ready():
	pass

func _on_body_entered(body):
	if not body.try_auto_teleport():
		if Players.is_round_ongoing:
			body.die()
			body.get_node("AnimatedSprite2D").visible = false
		body.lock_physics = true
	
