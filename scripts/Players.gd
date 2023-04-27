extends Node2D

var starting_ids = []

var winner_id = -1

var star_direction

var should_check_round_end = false
var is_round_ongoing = false
var lock_action = false

const play_to = 10
var score = {}

var spriteframe_data = [
	preload("res://animations/SpriteFrames_P1.tres"),
	preload("res://animations/SpriteFrames_P2.tres"),
	preload("res://animations/SpriteFrames_P3.tres"),
	preload("res://animations/SpriteFrames_P4.tres")
]

# settings
var orb_loss_numerator = 1
var orb_loss_denominator = 1

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

@export var mute_sound : bool = false

func _ready():
	pass
	
func initialize_for_new_round():
	winner_id = -1
	should_check_round_end = false
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
	should_check_round_end = true
	var i = 0
	var rng = RandomNumberGenerator.new()
	rng.randomize()
	var priorities = range(1, starting_ids.size() + 1)
	for x in starting_ids:
		var player_scene = load("res://scenes/Player.tscn")
		var player_instance = player_scene.instantiate()
		player_instance.id = int(x)
		player_instance.get_node("DeathParticles").modulate = player_colors[x - 1]
		player_instance.starting_theta = ((2 * PI * i / starting_ids.size()) + PI)
		i += 1
		
		# shuffle priorities for breaking ties in collision
		var priority = priorities[rng.randi_range(0, priorities.size() - 1)]
		priorities.erase(priority)
		player_instance.set_process_priority(priority)
		
		player_instance.get_node("AnimatedSprite2D").set_sprite_frames(spriteframe_data[x - 1])
		
		get_node("/root/Main").call_deferred("add_child", player_instance)
	
	is_round_ongoing = true

func _process(delta):
	elapsed_time += delta
	should_check_round_end = false
	
	if Input.is_action_just_pressed("exit_game"):
		is_round_ongoing = false
		get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")

func _on_RoundTimer_timeout():
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
