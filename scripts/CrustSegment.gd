extends Node2D

@export var arc_resolution: int = 100

# received fields
var colliders_per_segment
var arc_index
	
func set_arc_index(new_arc_index):
	arc_index = new_arc_index

func _ready():
	modulate = Color(1, 1, 1, 1)
	$Visuals/Warning.visible = false
		
func destroy():
	$AnimationPlayer.play("segment_destroy")

func _on_AnimationPlayer_animation_finished(anim_name):
	get_parent().remove_child(self)
