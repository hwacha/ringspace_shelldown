extends Area2D


func _ready():
	pass

func _on_OutOfBounds_body_shape_entered(body_rid, body, body_shape_index, local_shape_index):
	body.die()
	body.lock_physics = true
	body.get_node("AnimatedSprite2D").visible = false
