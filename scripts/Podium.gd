extends Node2D

@export var focus : Vector2 = Vector2(0, 270)
var arc_radius : float = 540.0

var accepting_input = false

var colors_by_rank = {
	'1': Color(0.83, 0.69, 0.22), # gold,
	'2': Color(0.67, 0.66, 0.68), # silver,
	'3': Color(0.60, 0.45, 0.29), # bronze,
	'4': Color(0.86, 0.85, 0.81), # pewter,
}

var players

var ranks_by_player = {}
var players_by_rank = {}

func switch_stepper(n: int):
	if n == 0:
		return 1
	elif n > 0:
		return -n
	elif n < 0:
		return -n + 1

func _ready():
	# determine player ranks
	var arr = []
	for id in Players.starting_ids:
		arr.push_back([id, Players.score[str(id)]])
	arr.sort_custom(func(a, b): return a[1] > b[1])
	
	var place_counter = 0
	var last_score = 1000000
	for i in range(arr.size()):
		var cur_score = arr[i][1]
		if cur_score < last_score:
			last_score = cur_score
			place_counter = i
		ranks_by_player[str(arr[i][0])] = place_counter + 1
	
	for player in ranks_by_player:
		var rank = ranks_by_player[player]
		if not players_by_rank.has(rank):
			players_by_rank[rank] = []
		players_by_rank[rank].push_back(player)

	var crust_segment_scene = preload("res://scenes/CrustSegment.tscn")
	
	# generate podium segments
	var offset_theta
	if players_by_rank.size() % 2 == 0:
		# even case
		offset_theta = (-PI/2) - (PI/16)
	else:
		# odd case
		offset_theta = -PI/2
	
	var switch_step_counter = 0
	for rank in players_by_rank:
		var crust_segment = crust_segment_scene.instantiate()
		var theta = offset_theta + switch_step_counter * (PI / 8)
		crust_segment.rotation = theta
		var unit_position = Vector2(cos(theta), sin(theta))
		crust_segment.transform.origin = focus + arc_radius * unit_position
		crust_segment.transform.origin += (rank - 1) * 120.0 * Vector2(0, 1)
		crust_segment.get_node("Visuals/Ring").texture = preload("res://assets/PodiumSegment.png")
		crust_segment.modulate = colors_by_rank[str(rank)]
		crust_segment.name = str(rank)
		
		add_child(crust_segment)
		
		switch_step_counter = switch_stepper(switch_step_counter)
		
	# animate players
	var animation = Animation.new()
	animation.length = 3.0
	
	var track_index_starfield = animation.add_track(Animation.TYPE_VALUE)
	var track_index_camera = animation.add_track(Animation.TYPE_VALUE)
	
	animation.track_set_path(track_index_starfield, "Starfield:position")
	animation.track_set_path(track_index_camera, "Camera2D:position")
	
	var starfield = get_parent().get_node("Starfield")
	starfield.rotating = false
	
	var my_position_in_main = self.transform.origin + get_parent().transform.origin
	
	animation.track_insert_key(track_index_starfield, 0.0, starfield.transform.origin)
	animation.track_insert_key(track_index_starfield, 3.0, my_position_in_main)
	
	animation.track_insert_key(track_index_camera, 0.0, get_parent().get_node("Camera2D").transform.origin)
	animation.track_insert_key(track_index_camera, 3.0, my_position_in_main)
	
	players = get_parent().get_children().filter(func(node): return node is Player)
	
	var rank_indeces = {}
	for player in players:
		player.lock_physics = true
		player.get_node("CollisionShapeForGround").disabled = true
		player.get_node("CollisionShapeForOrb").disabled = true
		player.get_node("HurtBox/CollisionShape2D").disabled = true
		player.get_node("HitBox/CollisionShape2D").disabled = true
		player.get_node("Singularity/CollisionShape2D").disabled = true
		var player_sprite = player.get_node("AnimatedSprite2D")
		player.expanded = false
		player_sprite.animation = "fastfalling"
		player_sprite.material.set("shader_parameter/is_invulnerable", false)
		player_sprite.material.set("shader_parameter/is_shielded", false)
		
		var track_index_rotation = animation.add_track(Animation.TYPE_VALUE)
		var track_index_position = animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track_index_rotation, player.name + ":rotation")
		animation.track_set_path(track_index_position, player.name + ":position")
		
		var rank = ranks_by_player[str(player.id)]
		var rank_index = 0
		if rank_indeces.has(str(rank)):
			rank_index = switch_stepper(rank_index)
		
		rank_indeces[str(rank)] = rank_index

		var num_others_in_rank = players_by_rank[rank].size()
		
		var destination_segment = get_node(str(ranks_by_player[str(player.id)]))
		var correction = 0
		if num_others_in_rank % 2 == 0:
			correction = 0.5
		var destination_rotation = (PI/2) + destination_segment.rotation + (rank_index - correction) * PI / (8 * num_others_in_rank)
		
		animation.track_insert_key(track_index_rotation, 0.0, player.rotation)
		animation.track_insert_key(track_index_rotation, 3.0, destination_rotation)
		
		var destination_position = my_position_in_main + focus + \
		(arc_radius + 50.0) * Vector2(cos(-PI/2 + destination_rotation), sin(-PI/2 + destination_rotation))
		
		destination_position += (rank - 1) * 120.0 * Vector2(0, 1)
		
		animation.track_insert_key(track_index_position, 0.0, player.transform.origin)
		animation.track_insert_key(track_index_position, 3.0, destination_position)
		
		var lib = AnimationLibrary.new()
		lib.add_animation("rise_to_podium", animation)
		var animation_player = AnimationPlayer.new()
		animation_player.set_root("/root/Main")
		animation_player.add_animation_library("custom", lib)
		
		animation_player.play("custom/rise_to_podium")
		
		animation_player.animation_finished.connect(_on_animation_finished)
		
		add_child(animation_player)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	if accepting_input and Input.is_anything_pressed():
		$Timer.stop()
		$AnimationPlayer.play("fadeout")

func _on_animation_finished(_anim):
	for player in players:
		var player_sprite = player.get_node("AnimatedSprite2D")
		if ranks_by_player[str(player.id)] == 1:
			player_sprite.animation = "victory" # change to victory jump
		else:
			player_sprite.animation = "default"
	
	accepting_input = true
	$Timer.start()
#		spawn_firework()

#func spawn_firework():
#	var winners = players_by_rank[1]
#
#	for winner in winners:
#		var firework = get_node(Players.player_names[winner - 1] + "Firework")
#		firework.visible = true
#		firework.get_node("AnimationPlayer").play("firework")


func _on_timer_timeout():
	$AnimationPlayer.play("fadeout")


func _on_animation_player_animation_finished(_anim_name):
	get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")
