extends Node2D

func _ready():
	$AnimationPlayer.play("arrival")
	

func _process(_delta):
	pass

func _on_decay_timeout():
	var players = get_parent().get_children().filter(func(node): return node is Player)
	for player in players:
		player.black_hole = null
		
	$CollisionShape2D.disabled = true
	$Singularity/CollisionShape2D.disabled = true
	
	$AnimationPlayer.play("departure")


func _on_body_entered(body):
	body.is_in_event_horizon = true

func _on_body_exited(body):
	body.is_in_event_horizon = false
	

func _on_singularity_area_entered(area):
	var player = area.get_parent()
	player.is_in_event_horizon = false
	player.spawn(false)


func _on_animation_player_animation_finished(anim_name):
	if anim_name == "arrival":
		$CollisionShape2D.disabled = false
		$Singularity.get_node("CollisionShape2D").disabled = false
		
		var players = get_parent().get_children().filter(func(node): return node is Player)
		for player in players:
			player.black_hole = self
			
		$Decay.start()
	else:
		get_parent().remove_child(self)
		queue_free()
	
