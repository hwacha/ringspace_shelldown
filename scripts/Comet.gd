extends Area2D

var centroid
var dir_sign
var player_who_shot

@export var speed : float = 1000.0

# Called when the node enters the scene tree for the first time.
func _ready():
	$Decay.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var diff = self.transform.origin - centroid
	
	var perp_velocity = diff.rotated(dir_sign * (PI / 2 + 0.01)).normalized() * delta * speed
	rotation = perp_velocity.angle() + PI
	self.transform.origin += perp_velocity


func _on_decay_timeout():
	get_parent().remove_child(self)
	self.queue_free()


func _on_body_entered(body):
	if body == player_who_shot or body.invulnerable:
		return
	else:
		body.killer = player_who_shot
		body.die()
