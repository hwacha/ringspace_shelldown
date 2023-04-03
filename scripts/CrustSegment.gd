extends Node2D

export(int) var arc_resolution = 100

# received fields
var midpoint_radius
var crust_size
var num_segments setget set_num_segments
var colliders_per_segment setget set_colliders_per_segment
var arc_index

# derived fields
var arc_angle
var offset

func set_num_segments(new_num_segments):
	num_segments = new_num_segments
	arc_angle = 2 * PI / num_segments

func set_colliders_per_segment(new_colliders_per_segment):
	colliders_per_segment = new_colliders_per_segment
	offset = -(arc_angle / colliders_per_segment) / 2

func _ready():
	pass

func _draw():
	draw_arc(Vector2(0, 0), \
		midpoint_radius, arc_index * arc_angle + offset, \
		(arc_index + 1) * arc_angle + offset, arc_resolution,\
		Color(0.125, 0.125, 0.125, 1), crust_size, true)
