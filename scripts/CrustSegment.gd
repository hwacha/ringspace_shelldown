extends Node2D

export(int) var arc_resolution = 100

# received fields
var midpoint_radius
var crust_size
var num_segments setget set_num_segments
var arc_index

# derived fields
var arc_angle


func set_num_segments(new_num_segments):
	num_segments = new_num_segments
	arc_angle = 2 * PI / num_segments

func _ready():
	pass

func _draw():
	draw_arc(Vector2(0, 0), \
		midpoint_radius, arc_index * arc_angle, (arc_index + 1) * arc_angle, arc_resolution,\
		Color(0.125, 0.125, 0.125, 1), crust_size, true)
