class_name CrustSegment
extends StaticBody2D

@export var arc_resolution: int = 100

# received fields
var colliders_per_segment

# random
@onready var rand = RandomNumberGenerator.new()

# state
@export var juttering : bool = false
var intact : bool = true
var occupying_players = []

var initial_segment_index

func _ready():
	rand.randomize()
	initial_segment_index = get_index()
		
func destroy():
	intact = false
	$AnimationPlayer.play("segment_destroy")

func _on_AnimationPlayer_animation_finished(_anim_name):
	if _anim_name == "segment_destroy":
		$Visuals/Ring.offset = Vector2(0, 0)
		$Repair.start()
#	get_parent().remove_child(self)
#	self.queue_free()

func repair():
	z_index = 0
	intact = true
	$AnimationPlayer.play("segment_repair")
	
func set_collision(enabled):
	var children = get_children()
	for child in children:
		if child is CollisionShape2D:
			child.disabled = not enabled
	
func _process(_delta):
	if juttering:
		var mem = rand.randf_range(-PI, PI)
		$Visuals/Ring.offset = 25 * Vector2(cos(mem), sin(mem))

func _on_area_2d_body_entered(body):
	if body is Player:
		if not body.dead and not body.id in occupying_players:
			occupying_players.push_back(body.id)


func _on_area_2d_body_exited(body):
	if body.id in occupying_players:
		occupying_players.erase(body.id)
		
func can_spawn_player():
	return intact and occupying_players.size() == 0
