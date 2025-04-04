extends Node2D

@onready var lensing = get_parent().get_node("BlackHoleLensing")
@export var _m : float = 0.0

var rotation_speed = PI / 15

var active = false

func _ready():
	lensing.material.set("shader_parameter/is_black_hole_active", true)
	lensing.material.set("shader_parameter/black_hole_center", self.global_position)
	$AnimationPlayer.play("arrival")
	

func _process(delta):
	if active:
		var centroid = Vector2(540, 540)
		self.transform.origin = (self.transform.origin - centroid).rotated(-Players.star_direction * rotation_speed * delta) + centroid
		lensing.material.set("shader_parameter/black_hole_center", self.global_position)
		lensing.material.set("shader_parameter/m", _m)

func _on_decay_timeout():
	var players = get_parent().get_node("PlayersOnField").get_children()
	for player in players:
		player.black_hole = null
		player.is_in_event_horizon = false
		
	$CollisionShape2D.disabled = true
	$Singularity/CollisionShape2D.disabled = true
	
	$AnimationPlayer.play("departure")


func _on_body_entered(body):
	body.is_in_event_horizon = true

func _on_body_exited(body):
	body.is_in_event_horizon = false
	

func _on_singularity_area_entered(area):
	var player = area.get_parent()
	player.position = Vector2(-10000, -10000)
	var black_hole_exit = preload("res://scenes/BlackHoleExit.tscn").instantiate()
	black_hole_exit.name = "blackhole_exit_" + str(player.id)
	black_hole_exit.get_node("PathFollow2D").modulate = player.color.lightened(0.2)
	black_hole_exit.player = player
	
	var destination_segment = player.find_crust_segment_to_spawn()
	black_hole_exit.destination_segment = destination_segment
	black_hole_exit.player_id = player.id
	
	if not player.id in destination_segment.occupying_players:
		destination_segment.occupying_players.push_back(player.id)
		
	var destination_position = Vector2(540, 540) + (1 - (48 / destination_segment.position.length())) * destination_segment.position
	black_hole_exit.curve.set_point_position(0, self.position)
	black_hole_exit.curve.set_point_position(1, destination_position)
	var a = destination_segment.position.rotated(PI/4) / sqrt(2)
	var b = destination_segment.position.rotated(-PI/4) / sqrt(2)
	var o = a if a.distance_to(Vector2(540, 540)) > b.distance_to(Vector2(540, 540)) else b
	black_hole_exit.curve.set_point_out(0, o)
	
	player.is_in_event_horizon = false
	player.segment_spawn_index = destination_segment.initial_segment_index
	
	player.expanded = false
	
	get_parent().add_child(black_hole_exit)
	


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "arrival":
		active = true
		$CollisionShape2D.disabled = false
		$Singularity.get_node("CollisionShape2D").disabled = false
		
		var players = get_parent().get_node("PlayersOnField").get_children()
		for player in players:
			player.black_hole = self
			
		$Decay.start()
	else:
		lensing.material.set("shader_parameter/is_black_hole_active", false)
		get_parent().remove_child(self)
		queue_free()
	
