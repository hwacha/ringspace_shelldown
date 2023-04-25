extends Area2D


func _ready():
	pass

func _on_OutOfBounds_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	body.die()
	body.lock_physics = true
	body.get_node("AnimatedSprite2D").visible = false
