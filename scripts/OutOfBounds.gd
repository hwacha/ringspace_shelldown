extends Area2D


func _ready():
	pass

func _on_body_entered(body):
	body.die()
	body.lock_physics = true
	body.get_node("AnimatedSprite2D").visible = false
