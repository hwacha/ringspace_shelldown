extends Node2D

export(int) var num_stars = 1000

var screen_size
var centroid

const rotation_speed = 0.03

func _ready():
	screen_size = get_viewport().size
	centroid = Vector2(screen_size.x / 2, screen_size.y / 2)

func _draw():
	# draw stars
	var rng = RandomNumberGenerator.new()
	rng.set_seed(hash("Starfields"))
	var theta = Players.elapsed_time * rotation_speed
	for _i in num_stars:
		var pos = Vector2(rng.randi_range(-screen_size.x * 0.5, screen_size.x * 1.5), rng.randi_range(-screen_size.y * 0.5, screen_size.y * 1.5))
		pos = (pos - centroid).rotated(theta * Players.star_direction) + centroid
		draw_circle(pos, rng.randf_range(0.5, 1.5), Color(1, 1, 1, 1))

func _process(delta):
	update()
