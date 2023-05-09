extends Node2D

var players_not_playing

# Called when the node enters the scene tree for the first time.
func _ready():
#	var bus_idx = AudioServer.get_bus_index("Master")
#	AudioServer.set_bus_mute(bus_idx, true)
	players_not_playing = [1, 2, 3, 4].filter(func(id): return id not in Players.starting_ids)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if not Players.lock_action:
		for id in players_not_playing:
			var button_pressed = Input.is_action_just_pressed("jump_p" + str(id))
			button_pressed = button_pressed or Input.is_action_just_pressed("fast_fall_p" + str(id))
			button_pressed = button_pressed or Input.is_action_just_pressed("use_p" + str(id))
			
			if button_pressed:
				players_not_playing.erase(id)
				# remove join text
				var hotjoin_text = $HotjoinText.get_node(str(id))
				$HotjoinText.remove_child(hotjoin_text)
				hotjoin_text.queue_free()
				# add score bubble
				$Score.queue_redraw()
				# add powerup node
				var powerup = preload("res://scenes/Powerup.tscn").instantiate()
				powerup.transform.origin = $Score.score_locations[str(id)]
				powerup.name += str(id)
				$Powerups.add_child(powerup)
				#spawn player
				Players.starting_ids.push_back(id)
				Players.score[str(id)] = 0
				Players.respawn_player(id, Players.starting_ids.size())

func on_postround_end():
	# make a podium
	var podium = preload("res://scenes/Podium.tscn").instantiate()
	podium.transform.origin = Vector2(540, -1080)
	add_child(podium)

#func _on_child_entered_tree(node):
#	if node is Player and not node.first_spawn:
#		node.on_respawn()
