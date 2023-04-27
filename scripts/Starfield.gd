extends Sprite2D

@export var rotation_speed: float = 0.03

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate(Players.star_direction * delta * rotation_speed)
