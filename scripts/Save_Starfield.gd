extends Node2D

@export var num_stars: int = 1000

var screen_size
var centroid

func _ready():
	screen_size = get_viewport().size
	centroid = Vector2(screen_size.x / 2, screen_size.y / 2)

func _draw():
	# draw stars
	var rng = RandomNumberGenerator.new()
	rng.set_seed(hash("Starfields"))
	for _i in num_stars:
		var pos = Vector2(rng.randi_range(-screen_size.x * 0.5, screen_size.x * 1), rng.randi_range(-screen_size.y * 0.5, screen_size.y * 1))
		draw_circle(pos, rng.randf_range(0.5, 3), Color(1, 1, 1, 1))

func _process(delta):
	update()
	if Input.is_action_just_pressed("ui_accept"):
		var img = get_tree().root.get_viewport().get_texture().get_data()
		img.flip_y()
		img.save_png("res://assets/starfield.png")
