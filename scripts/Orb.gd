extends Area2D
class_name Orb

var id
var centroid = Vector2(540, 540)

# parameters
var points_to_free_destination = 5
var points_to_claimant = 2

# state
var traveling : bool = true
var black_hole = null
var event_horizon_entry_point = null
var time_in_event_horizon : float = 0 # seconds
var just_had_black_hole : bool = false
var claimed : bool = false
var next_claimant : Player = null : set = set_next_claimant
var next_claimant_id : int = -1

var claimant_destination_offset = null

var rand = RandomNumberGenerator.new()

func set_next_claimant(new_next_claimant):
	next_claimant = new_next_claimant
	if new_next_claimant == null:
		next_claimant_id = -1
	else:
		next_claimant_id = new_next_claimant.id

func _ready():
	rand.randomize()

func _process(delta):
	if traveling and next_claimant != null:
		$AnimationPlayer.get_animation("custom/travel_to_claimant")\
		.track_set_key_value(0, 1, next_claimant.transform.origin + claimant_destination_offset)
	elif black_hole == null:
		if just_had_black_hole:
			if not claimed:
				set_new_destination()
			event_horizon_entry_point = null
			time_in_event_horizon = 0
			just_had_black_hole = false
	else:
		var period : float = 7.5
		if event_horizon_entry_point == null:
			event_horizon_entry_point = transform.origin - black_hole.transform.origin
		var dest = 25 * event_horizon_entry_point.normalized()
		var pos = lerp(event_horizon_entry_point, dest, time_in_event_horizon / period)
		transform.origin = black_hole.transform.origin + pos
		time_in_event_horizon += delta
		time_in_event_horizon = clampf(time_in_event_horizon, 0.0, period)

func _on_area_entered(area):
	if area is OrbVacuum:
		if not claimed:
			claimed = true
			black_hole = null
			$WaitingToTravel.stop()
			$AnimatedSprite2D.animation = "default"
			next_claimant = area.player_who_threw
			set_new_destination()
	elif area.name == "OrbBox": # it's the player
		var player = area.get_parent()
		if not (claimed or traveling or player.dead):
			claimed = true
			black_hole = null
			$WaitingToTravel.stop()
			$AnimatedSprite2D.animation = "default"
			get_parent().call_deferred("remove_child", self)
			var new_orbs = player.get_node("Orbs")
			new_orbs.call_deferred("add_child", self)
			new_orbs.call_deferred("on_add_orb", self)
	
	else: # it's the event horizon of the black hole
		if area.active and not claimed:
			black_hole = area
			just_had_black_hole = true
			$WaitingToTravel.stop()
			traveling = false
			var cur_position = transform.origin
			$AnimationPlayer.stop()
			transform.origin = cur_position
			$AnimatedSprite2D.animation = "grabbable"

func set_new_destination():
	traveling = true
	$AnimatedSprite2D.animation = "default"

	var animation
	if next_claimant == null:
		animation = $AnimationPlayer.get_animation("custom/travel_to_destination")
	else:
		animation = $AnimationPlayer.get_animation("custom/travel_to_claimant")

	animation.track_set_key_value(0, 0, self.transform.origin)
	
	# pick random points within the sphere
	if next_claimant == null:
		for i in range(1, points_to_free_destination):
			var r = 480 * sqrt(rand.randf())
			var theta = rand.randf() * 2 * PI
			
			var waypoint = r * Vector2(sin(theta), cos(theta)) + centroid
			
			animation.track_set_key_value(0, i, waypoint)

		$AnimationPlayer.play("custom/travel_to_destination")
	else:
		var claimant_destination = next_claimant.transform.origin
		for i in range(1, points_to_claimant - 1):
			var r = 480 * sqrt(rand.randf())
			var theta = rand.randf() * 2 * PI
			
			var waypoint = r * Vector2(cos(theta), sin(theta)) + centroid
			
			animation.track_set_key_value(0, i, waypoint)
		
		# randomly set desination within orb orbit radius
		var r = 40
		var theta = rand.randf() * 2 * PI
		
		claimant_destination_offset = r * Vector2(cos(theta), sin(theta))
		var claimant_destination_point = + claimant_destination + claimant_destination_offset
		
		animation.track_set_key_value(0, points_to_claimant - 1, claimant_destination_point)
		$AnimationPlayer.play("custom/travel_to_claimant")
		

func create_animation():
	var anim_free = Animation.new()
	var anim_claimed = Animation.new()
	
	anim_free.length = 2.0
	anim_claimed.length = 0.5

	var track_index_free = anim_free.add_track(Animation.TYPE_VALUE)
	anim_free.track_set_interpolation_type(track_index_free, Animation.INTERPOLATION_CUBIC)
	anim_free.track_set_path(track_index_free, ".:position")
	
	var track_index_claimed = anim_claimed.add_track(Animation.TYPE_VALUE)
	anim_claimed.track_set_interpolation_type(track_index_claimed, Animation.INTERPOLATION_CUBIC)
	anim_claimed.track_set_path(track_index_claimed, ".:position")

	for t in range(points_to_free_destination):
		anim_free.track_insert_key(track_index_free, t * 0.5, Vector2(0, 0))
	
	for t in range(points_to_claimant):
		anim_claimed.track_insert_key(track_index_free, t * 0.5, Vector2(0, 0))
	
	var lib = AnimationLibrary.new()
	lib.add_animation("travel_to_destination", anim_free)
	lib.add_animation("travel_to_claimant", anim_claimed)
	
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	anim_player.add_animation_library("custom", lib)
	
	anim_player.animation_finished.connect(_on_animation_player_animation_finished)
	
	add_child(anim_player)

func _on_tree_entered():
	var anim = get_node_or_null("AnimationPlayer")
	if anim == null:
		create_animation()

	if get_parent().name == "Main":
		set_new_destination()

func _on_animation_player_animation_finished(_anim_name):
	traveling = false
	if next_claimant == null:
		if claimed:
			assert(next_claimant_id != -1)
			get_parent().call_deferred("remove_child", self)
			var claimed_player = get_node_or_null("/root/Main/Players/" + str(next_claimant_id))
			if claimed_player == null: # yet to respawn
				Players.stored_orbs[next_claimant_id - 1].push_back(self)
			else: # respawned
				claimed_player.get_node("Orbs").call_deferred("add_child", self)
				claimed_player.get_node("Orbs").call_deferred("on_add_orb", self)
				
		else:
			# unclaimed orbs should be grabbable and move around
			$AnimatedSprite2D.animation = "grabbable"
			$WaitingToTravel.start()
	else:
		get_parent().call_deferred("remove_child", self)
		if next_claimant.dead:
			var stored_orbs = Players.stored_orbs
			stored_orbs[next_claimant.id - 1].push_back(self)
		else:
			next_claimant.get_node("Orbs").call_deferred("add_child", self)
			next_claimant.get_node("Orbs").call_deferred("on_add_orb", self)
		
		next_claimant = null
	

func _on_waiting_to_travel_timeout():
	if not claimed:
		set_new_destination()


func _on_animated_sprite_2d_animation_changed():
	var anim_sprite = $AnimatedSprite2D
#	print("animation changed: " + anim_sprite.animation)
	anim_sprite.material.set("shader_parameter/is_grabbable", \
		anim_sprite.animation == "grabbable")
