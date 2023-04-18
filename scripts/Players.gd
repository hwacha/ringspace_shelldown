extends Node2D

var starting_ids = []
var living_ids = []
var killed_ids = []

var winner_id = -1

var should_check_round_end = false
var is_round_ongoing = false

const play_to = 3
var score = {}
var star_direction

var starfield_rotation = 0

const initial_settings = {
	"fast_fall_enabled": true,
	"invert_controls": false,
	"segment_decay_enabled": true,
}

var settings = initial_settings

const player_colors = [
	Color(1, 0, 0),
	Color(0, 0.5, 1),
	Color(0, 1, 0),
	Color(1, 1, 0),
]

const player_names = [
	"Red",
	"Blue",
	"Green",
	"Yellow"
]

var elapsed_time = 0

func _ready():
	killed_ids = []
	
func initialize_for_new_round():
	winner_id = -1
	should_check_round_end = false
	living_ids = []
	killed_ids = []
	is_round_ongoing = false

func set_player_ids(x):
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	star_direction = (rng.randi_range(0, 1) * 2) - 1
	
	starting_ids = x
	
	score = {}
	for id in starting_ids:
		score[str(id)] = 0
	
func spawn_players():
	living_ids = starting_ids.duplicate()
	should_check_round_end = true
	var i = 0
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var priorities = range(1, starting_ids.size() + 1)
	for x in starting_ids:
		var player_scene = load("res://scenes/Player.tscn")
		var player_instance = player_scene.instantiate()
		player_instance.id = int(x)
		player_instance.modulate = player_colors[x - 1]
		player_instance.starting_theta = ((2 * PI * i / starting_ids.size()) + PI)
		i += 1
		
		# shuffle priorities for breaking ties in collision
		var priority = priorities[rng.randi_range(0, priorities.size() - 1)]
		priorities.erase(priority)
		player_instance.set_process_priority(priority)
		
		get_node("/root/Main").call_deferred("add_child", player_instance)
	
	is_round_ongoing = true

func player_killed(id):
	if is_round_ongoing:
		if living_ids.size() > 1 or starting_ids.size() == 1:
			killed_ids.push_back(id)
		
func handle_killed_players():
	for killed_id in killed_ids:
		should_check_round_end = true
		living_ids.erase(killed_id)

	if should_check_round_end:
		if living_ids.size() == 1 and starting_ids.size() != 1:
			score[str(living_ids[0])] += 1
			get_node("/root/Main/Score").queue_redraw()
#			for player_id in score:
#				print(player_id +  " -> " + str(score[player_id]))
		if  living_ids.size() == 0 or \
			(living_ids.size() == 1 and starting_ids.size() != 1):
			if $RoundTimer.get_time_left() == 0:
				$RoundTimer.start()

func _process(delta):
	elapsed_time += delta
	handle_killed_players()
	killed_ids = []
	should_check_round_end = false
	
	if Input.is_action_just_pressed("exit_game"):
		is_round_ongoing = false
		get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")

func _on_RoundTimer_timeout():
	if living_ids.size() > 0 and score[str(living_ids[0])] >= play_to:
		winner_id = living_ids[0]
		get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
	else:
		starfield_rotation = get_node("/root/Main/Starfield").rotation
		initialize_for_new_round()
		get_tree().change_scene_to_file("res://scenes/main.tscn")
