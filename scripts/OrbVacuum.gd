extends Area2D

var player_who_threw
var velocity

var speed = 0.4

# Called when the node enters the scene tree for the first time.
func _ready():
	modulate.a = 0.5
	$Decay.start()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	transform.origin += velocity * speed * delta
	scale += Vector2(0.2, 0.2)


func _on_decay_timeout():
	get_parent().remove_child(self)
	queue_free()
