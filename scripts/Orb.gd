extends Area2D

var id
var centroid

# parameters
var points_to_free_destination = 5
var points_to_claimant = 2

# state
var traveling : bool = true
var claimed : bool = false
var next_claimant : Player = null
var claimant_destination_offset = null

var rand = RandomNumberGenerator.new()

func _ready():
	rand.randomize()


func _process(_delta):
	if traveling and next_claimant != null:
		$AnimationPlayer.get_animation("custom/travel_to_claimant")\
		.track_set_key_value(0, 1, next_claimant.transform.origin + claimant_destination_offset)
	pass

func _on_body_entered(body):
	if not (claimed or traveling or body.dead):
		$WaitingToTravel.stop()
		get_parent().call_deferred("remove_child", self)
		var new_orbs = body.get_node("Orbs")
		new_orbs.call_deferred("add_child", self)
		new_orbs.call_deferred("on_add_orb", self, true)

func set_new_destination():
	traveling = true

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
	anim_free.length = 1.0

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
		$WaitingToTravel.start()
	else:
		get_parent().call_deferred("remove_child", self)
		next_claimant.get_node("Orbs").call_deferred("add_child", self)
		next_claimant.get_node("Orbs").call_deferred("on_add_orb", self, true)
		next_claimant = null
	

func _on_waiting_to_travel_timeout():
	if not claimed:
		set_new_destination()
