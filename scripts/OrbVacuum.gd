extends Area2D
class_name OrbVacuum

var player_who_threw
var velocity

var speed = 0.4

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate.a = 0.5
	$Decay.start()
	$Suck.play()
	$Lifetime.play("lifetime")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transform.origin += velocity * speed * delta
	scale += delta * 15 * Vector2(1, 1)
	rotate(-2.0 * delta)

func _on_decay_timeout():
	get_parent().remove_child(self)
	queue_free()
