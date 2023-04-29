extends Area2D


func _ready():
	$Decay.start()

func _process(_delta):
	pass

func _on_body_entered(body):
	if not body.invulnerable:
		body.die()
		body.lock_physics = true
		body.get_node("AnimatedSprite2D").visible = false


func _on_decay_timeout():
	get_parent().remove_child(self)
	queue_free()
