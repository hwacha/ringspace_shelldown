extends Node2D

var players_not_playing

var rng = RandomNumberGenerator.new()

func _ready():
	Players.lock_action = true
#	var bus_idx = AudioServer.get_bus_index("Master")
#	AudioServer.set_bus_mute(bus_idx, true)
	players_not_playing = [1, 2, 3, 4].filter(func(id): return id not in Players.starting_ids)
	rng.randomize()

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

func on_crust_ready():
	Players.spawn_players()
	$Camera2D/AnimationPlayer.play("zoom_out")

func _on_round_begin():
	Players.lock_action = false
	$CrustDecay.start()
	$MatchTimer.start()
	$TimeLeftLabel.visible = true
	$PowerupTimer.start()
	$ObstacleTimer.start()

func _on_match_timer_timeout():
	Players.end_game()

func on_postround_end():
	# make a podium
	var podium = preload("res://scenes/Podium.tscn").instantiate()
	podium.transform.origin = Vector2(540, -1080)
	add_child(podium)

#func _on_child_entered_tree(node):
#	if node is Player and not node.first_spawn:
#		node.on_respawn()


func _on_powerup_timer_timeout():
	var old_collectable = get_node_or_null("Collectable")
	if old_collectable != null:
		remove_child(old_collectable)
		old_collectable.queue_free()
			
	var new_collectable = preload("res://scenes/Collectable.tscn").instantiate()
	var collectable_names = ["teleport", "expand", "fast", "shield", "comet", "vacuum"]
	
	# normalize probability of orb vacuum
	# to number of orbs on field in range [0, 2/5]
	# where probability maxes out at win score
	var orb_vac_max_probability = 2.0 / 5.0
	var num_orbs_on_field = get_children().filter(func(node): return node is Orb).size()
	var orb_vac_probability = float(min(num_orbs_on_field, Players.play_to)) * \
							(orb_vac_max_probability / Players.play_to)
	# normalize probability of teleport
	# to number of decayed crust segments [0, 1/4]
	var teleport_max_probability = 1.0 / 4.0
	var max_decayed_segments = $Crust.num_segments - $Crust.segments_to_keep.size()
	var cur_decayed_segments = $Crust.num_segments - $Crust.get_children().size()
	var teleport_probability = teleport_max_probability * (float(cur_decayed_segments) / float(max_decayed_segments))
	# probability of speedy is pmax(fast) - [pmax(fast)/pmax(teleport)] * p(teleport)
	var max_fast_probability = 0.25
	var fast_probability = max_fast_probability * (1.0 - (teleport_probability / teleport_max_probability))
	# probability of remaining powerups are
	# equally divided among the remaining probability
	var remaining_probability = 1.0 - (orb_vac_probability + teleport_probability + fast_probability)
	var generic_probability = remaining_probability / (collectable_names.size() - 3)
	
	var collectable_probabilities = {
		"vacuum": orb_vac_probability,
		"teleport": teleport_probability,
		"fast": fast_probability,
		"expand": generic_probability,
		"shield": generic_probability,
		"comet": generic_probability,
	}
	
	var rand = rng.randf()
	var lower_bound = 0.0
	var greater_bound = 0.0
	for collectable_name in collectable_probabilities:
		var collectable_probability = collectable_probabilities[collectable_name]
		greater_bound = lower_bound + collectable_probability
		if rand > lower_bound and rand <= greater_bound:
			# spawn collectable
			new_collectable.collectable = collectable_name
			new_collectable.transform.origin = Vector2(540, 540)
			add_child(new_collectable)
			break
		lower_bound += collectable_probability


func _on_obstacle_timeout():
	if not Players.is_round_ongoing:
		return

	var obstacles = [preload("res://scenes/Sun.tscn"), preload("res://scenes/BlackHole.tscn")]
	var rand = rng.randi_range(0, obstacles.size() - 1)
	
	var obstacle = obstacles[rand].instantiate()
	
	obstacle.transform.origin = Vector2(540, 540)
	
	var rand_r = 350.0 * sqrt(rng.randf())
	var rand_theta = rng.randf() * 2 * PI
	
	obstacle.transform.origin += rand_r * Vector2(cos(rand_theta), sin(rand_theta))
	
	add_child(obstacle)
