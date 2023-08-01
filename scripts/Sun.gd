extends Area2D

@export var is_approaching = true

var rotation_speed = 2 * PI / 15

func _ready():
	$AnimationPlayer.play("arrival")

func _process(delta):
	if not is_approaching:
		var centroid = Vector2(540, 540)
		self.transform.origin = (self.transform.origin - centroid).rotated(-Players.star_direction * rotation_speed * delta) + centroid

func _on_body_entered(body):
	if is_approaching:
		return

	if not body.invulnerable:
		if not body.try_auto_teleport():
			body.die()
			body.lock_physics = true
			body.get_node("AnimatedSprite2D").visible = false


func _on_decay_timeout():
	$CollisionShape2D.disabled = true
	$Body/Halo.material.set("shader_parameter/is_active", false)
	$Fire.stop()
	$AnimationPlayer.play("departure")


func _on_animation_player_animation_finished(anim_name):
	if (anim_name == "arrival"):
		$CollisionShape2D.disabled = false
		$Body/Halo.material.set("shader_parameter/is_active", true)
		$Fire.play()
		$Decay.start()
		is_approaching = false
	else:
		get_parent().remove_child(self)
		queue_free()
