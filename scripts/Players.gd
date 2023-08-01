extends Node2D

var starting_ids = []

var star_direction

var is_round_ongoing = false
var lock_action = false

var play_to = 24
var score = {}

var control_icons = [
	{
		"has_analog_stick": false,
		"run": "keys_0",
		"jump": preload("res://assets/Keys/0/Up.png"),
		"fastfall": preload("res://assets/Keys/0/Down.png"),
		"powerup": preload("res://assets/Keys/0/UpLeft.png"),
		"start": preload("res://assets/Keys/0/Start.png")
	},
	{
		"has_analog_stick": false,
		"run": "keys_1",
		"jump": preload("res://assets/Keys/1/Up.png"),
		"fastfall": preload("res://assets/Keys/1/Down.png"),
		"powerup": preload("res://assets/Keys/1/UpLeft.png"),
		"start": preload("res://assets/Keys/1/Start.png")
	},
	{
		"has_analog_stick": false,
		"run": "keys_0",
		"jump": preload("res://assets/Keys/2/Up.png"),
		"fastfall": preload("res://assets/Keys/2/Down.png"),
		"powerup": preload("res://assets/Keys/2/UpLeft.png"),
		"start": preload("res://assets/Keys/2/Start.png")
	},
	{
		"has_analog_stick": false,
		"run": "keys_0",
		"jump": preload("res://assets/Keys/3/Up.png"),
		"fastfall": preload("res://assets/Keys/3/Down.png"),
		"powerup": preload("res://assets/Keys/3/UpLeft.png"),
		"start": preload("res://assets/Keys/3/Start.png")
	},
]

const spriteframe_data = [
	preload("res://animations/SpriteFrames_P1.tres"),
	preload("res://animations/SpriteFrames_P2.tres"),
	preload("res://animations/SpriteFrames_P3.tres"),
	preload("res://animations/SpriteFrames_P4.tres")
]

const player_scene = preload("res://scenes/Player.tscn")

# settings
var orb_loss_numerator_kill     = 1
var orb_loss_denominator_kill   = 2

var orb_loss_numerator_hazard   = 1
var orb_loss_denominator_hazard = 4

var player_colors = [
	Color.hex(0xa40909ff) + Color(0.2, 0.2, 0.2),
	Color.hex(0x0a1ea2ff) + Color(0.2, 0.2, 0.2),
	Color.hex(0x258e1dff) + Color(0.2, 0.2, 0.2),
	Color.hex(0xcec645ff) + Color(0.2, 0.2, 0.2),
]

var player_invulnerability_colors = [
	Color.hex(0xa40909ff),
	Color.hex(0x0a1ea2ff),
	Color.hex(0x258e1dff),
	Color.hex(0xcec645ff),
]

const player_names = [
	"Red",
	"Blue",
	"Green",
	"Yellow"
]

var stored_orbs = [
	[],
	[],
	[],
	[]
]

var elapsed_time = 0

@export var mute_sound : bool = false

func on_controller_change(controller_id: int, connected: bool):
	if controller_id > 3:
		return

	var joy_name = Input.get_joy_name(controller_id)
	
	var path = "res://assets/"
	var run_animation = ""
	
	if connected:
		control_icons[controller_id]["has_analog_stick"] = true
		
		if joy_name == "PS4 Controller":
			path += "PS4/"
			run_animation = "ps4"
		elif joy_name == "PS5 Controller":
			path += "PS5/"
			run_animation = "ps5"
		elif joy_name.begins_with("Xbox Series"):
			path += "Xbox_Series/"
			run_animation = "xbox"
		elif joy_name == "Joy-Con (L)":
			path += "Switch_Left/"
			run_animation = "switch_left"
		elif joy_name == "Joy-Con (R)":
			path += "Switch_Right/"
			run_animation = "switch_right"
		elif joy_name.begins_with("Xbox") or "Arcade" in joy_name:
			path += "Xbox_360/"
			run_animation = "xbox_360"
		else:
			path += "Generic/"
			run_animation = "generic"
		
		control_icons[controller_id]["jump"] = load(path +  "Bottom_Action.png")
		control_icons[controller_id]["fastfall"] = load(path + "Right_Action.png")
		control_icons[controller_id]["powerup"] = load(path + "Left_Action.png")
		
	else: # keyboard input
		path += "Keys/" + str(controller_id) + "/"
		run_animation = "keys_" + str(controller_id)
		control_icons[controller_id]["jump"] = load(path + "Up.png")
		control_icons[controller_id]["fastfall"] = load(path + "Down.png")
		control_icons[controller_id]["powerup"] = load(path + "UpLeft.png")

	control_icons[controller_id]["start"] = load(path + "Start.png")
	control_icons[controller_id]["run"] = run_animation
	
	var opening_screen = get_node_or_null("/root/OpeningScreen")
	var main = get_node_or_null("/root/Main")
	if opening_screen != null:
		opening_screen.update_controls(controller_id)
	
	if main != null:
		main.update_controls(controller_id)

func _ready():
	Input.joy_connection_changed.connect(on_controller_change)
	for i in range(4):
		on_controller_change(i, Input.get_joy_name(i) != "")
	
func initialize_for_new_round():
	is_round_ongoing = false

func set_player_ids(x):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	star_direction = (rng.randi_range(0, 1) * 2) - 1
	
	starting_ids = x
	
	score = {}
	for id in starting_ids:
		score[str(id)] = 0
	
func player_constructor(id, priority):
	var player_instance = player_scene.instantiate()
	player_instance.name = str(id)
	player_instance.id = id
	player_instance.color = player_colors[id - 1]
	player_instance.get_node("DeathParticles").modulate = player_instance.color
	player_instance.get_node("StompParticles").modulate = player_instance.color
	player_instance.get_node("DeathParticles").modulate.a = 0.3
	player_instance.get_node("StompParticles").modulate.a = 0.6
	player_instance.get_node("AnimatedSprite2D").material.set("shader_parameter/primary_color", player_invulnerability_colors[id - 1])
	player_instance.starting_theta = 0
	player_instance.set_process_priority(priority)
	player_instance.get_node("AnimatedSprite2D").set_sprite_frames(spriteframe_data[id - 1])
	return player_instance
	
func spawn_players():
	var i = 0
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var priorities = range(1, starting_ids.size() + 1)
	for x in starting_ids:
		# shuffle priorities for breaking ties in collision
		var priority = priorities[rng.randi_range(0, priorities.size() - 1)]
		priorities.erase(priority)
		var player_instance = player_constructor(int(x), priority)
		player_instance.starting_theta = ((2 * PI * i / starting_ids.size()) + PI)
		i += 1
		
		get_node("/root/Main/PlayersOnField").call_deferred("add_child", player_instance)
	
	is_round_ongoing = true
	
func respawn_player(player_id, priority):
	var next_player = player_constructor(player_id, priority)
	next_player.first_spawn = false
	
	var next_player_orbs = next_player.get_node("Orbs")

	for stored_orb in stored_orbs[player_id - 1]:
		next_player_orbs.add_child(stored_orb)
		next_player_orbs.on_add_orb(stored_orb)
	
	stored_orbs[player_id - 1] = []
	
	var main = get_node("/root/Main")
	
	if main.has_node("BlackHole"):
		next_player.black_hole = main.get_node("BlackHole")
		
	main.get_node("PlayersOnField").call_deferred("add_child", next_player)


func _process(delta):
	elapsed_time += delta
	
	var main = get_node_or_null("/root/Main")
	
	if main != null:
		for id in score.keys():
			var old_score = score[id]
			var player_node = get_node_or_null("/root/Main/PlayersOnField/" + id)
			if player_node == null:
				player_node = get_node("/root/Main/PlayersOnField/" + id + "_(dead)")
			var new_score = 0
			if player_node != null:
				new_score = player_node.get_node("Orbs").get_child_count()
			new_score += stored_orbs[int(id) - 1].size()
			if old_score != new_score:
				score[id] = new_score
				get_node("/root/Main/Score").queue_redraw()
			if score[id] >= play_to:
				end_game(true)
			
	
	if Input.is_action_just_pressed("exit_game"):
		is_round_ongoing = false
		$PostMatchTimer.stop()
		Engine.set_time_scale(1)
		get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")
		
		var testing_stage = get_node_or_null("/root/TestingStage")
		if testing_stage != null:
			get_tree().get_root().remove_child(testing_stage)
		
func end_game(is_max_score: bool):
	if is_round_ongoing:
		var round_timer = get_node("/root/Main/MatchTimer")
		var time_left_label = get_node("/root/Main/TimeLeftLabel")
		if is_max_score:
			time_left_label.final_time = round_timer.time_left
		round_timer.stop()
		
		var round_text = get_node("/root/Main/RoundText")
		round_text.text = "[center]MATCH[/center]"
		round_text.modulate.a = 1
		get_node("/root/Main/Background Music").stop()
		get_node("/root/Main/End Stab").play()
		Engine.set_time_scale(0.6)
		is_round_ongoing = false
		lock_action = true
		$PostMatchTimer.start()

func _on_post_match_timer_timeout():
	Engine.set_time_scale(1)
	get_node("/root/Main").on_postround_end()
