extends AnimatedSprite2D


#func _ready():
#	pass
#
#func _process(delta):
#	pass

func _on_animation_finished():
	get_parent().remove_child(self)
	queue_free()
