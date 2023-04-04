extends Node2D

export(int) var arc_resolution = 100

# received fields
var midpoint_radius
var crust_size
var num_segments setget set_num_segments
var colliders_per_segment setget set_colliders_per_segment
var arc_index setget set_arc_index

# derived fields
var arc_angle
var offset

# for warning animation
export(bool) var is_flash_on setget set_flash

func set_num_segments(new_num_segments):
	num_segments = new_num_segments
	arc_angle = 2 * PI / num_segments
	
func set_arc_index(new_arc_index):
	arc_index = new_arc_index
	var theta = arc_angle * (arc_index + 0.4)
	$Sprite.rotate(theta - PI/2)
	$Sprite.transform.origin = midpoint_radius * 0.8 * Vector2(cos(theta), sin(theta))
	
func set_flash(new_is_flash_on):
	is_flash_on = new_is_flash_on
	update()

func set_colliders_per_segment(new_colliders_per_segment):
	colliders_per_segment = new_colliders_per_segment
	offset = -(arc_angle / colliders_per_segment) / 2

func _ready():
	is_flash_on = false
	$Sprite.visible = false

func _draw():
	var color = Color(0.125, 0.125, 0.125, 1)
	if is_flash_on:
		color = Color(1, 0.7, 0.3, 1)
	draw_arc(Vector2(0, 0), \
		midpoint_radius, arc_index * arc_angle + offset, \
		(arc_index + 1) * arc_angle + offset, arc_resolution,\
		color, crust_size, true)
		
func destroy():
	$AnimationPlayer.play("segment_destroy")

func _on_AnimationPlayer_animation_finished(anim_name):
	get_parent().remove_child(self)
