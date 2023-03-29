extends Sprite

export(float) var rotation_speed = 0.03

# Called when the node enters the scene tree for the first time.
func _ready():
	transform.origin.x = get_viewport().size.x / 2
	transform.origin.y = get_viewport().size.y / 2
	rotate(Players.starfield_rotation)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate(Players.star_direction * delta * rotation_speed)
	pass
