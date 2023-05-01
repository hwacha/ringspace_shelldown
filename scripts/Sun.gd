extends Area2D

@export var is_approaching = true

func _ready():
	$AnimationPlayer.play("arrival")

func _process(_delta):
	pass

func _on_body_entered(body):
	if is_approaching:
		return

	if not (body.invulnerable or body.shielded):
		if not body.try_auto_teleport():
			body.die()
			body.lock_physics = true
			body.get_node("AnimatedSprite2D").visible = false


func _on_decay_timeout():
	get_parent().remove_child(self)
	queue_free()

func _on_animation_player_animation_finished(_anim_name):
	$CollisionShape2D.disabled = false
	$Decay.start()
	is_approaching = false
