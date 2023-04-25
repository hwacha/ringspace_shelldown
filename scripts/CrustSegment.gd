class_name CrustSegment
extends StaticBody2D

@export var arc_resolution: int = 100

# received fields
var colliders_per_segment

# random
@onready var rand = RandomNumberGenerator.new()

# state
@export var juttering : bool = false
@onready var original_position = $Visuals/Ring.transform.origin

func _ready():
	rand.randomize()
		
func destroy():
	$AnimationPlayer.play("segment_destroy")

func _on_AnimationPlayer_animation_finished(_anim_name):
	get_parent().remove_child(self)
	
func disable_collision():
	var children = get_children()
	for child in children:
		if child is CollisionShape2D:
			child.disabled = true
	
func _process(_delta):
	if juttering:
		var mem = rand.randf_range(-PI, PI)
		$Visuals/Ring.transform.origin = original_position + 5 * Vector2(cos(mem), sin(mem))
