extends Node2D

@export var arc_resolution: int = 100

# received fields
var colliders_per_segment
var arc_index

# for warning animation
@export var is_flash_on: bool: set = set_flash
	
func set_arc_index(new_arc_index):
	arc_index = new_arc_index
	
func set_flash(new_is_flash_on):
	is_flash_on = new_is_flash_on

func _ready():
	is_flash_on = false
	$Visuals/Warning.visible = false
		
func destroy():
	$AnimationPlayer.play("segment_destroy")

func _on_AnimationPlayer_animation_finished(anim_name):
	get_parent().remove_child(self)
