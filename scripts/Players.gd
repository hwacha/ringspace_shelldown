extends Node2D

var starting_ids = []

var winner_id = -1

var star_direction

var is_round_ongoing = false
var lock_action = false

var play_to = 12
var score = {}

const spriteframe_data = [
	preload("res://animations/SpriteFrames_P1.tres"),
	preload("res://animations/SpriteFrames_P2.tres"),
	preload("res://animations/SpriteFrames_P3.tres"),
	preload("res://animations/SpriteFrames_P4.tres")
]

const player_scene = preload("res://scenes/Player.tscn")

# settings
var orb_loss_numerator = 1
var orb_loss_denominator = 2

const player_colors = [
	Color(1, 0.1, 0.1),
	Color(0, 0.5, 1),
	Color(0, 1, 0),
	Color(1, 1, 0),
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

func _ready():
	pass
	
func initialize_for_new_round():
	winner_id = -1
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
	player_instance.id = id
	player_instance.get_node("DeathParticles").modulate = player_colors[id - 1]
	player_instance.get_node("AnimatedSprite2D").material.set("shader_param/primary_color", player_invulnerability_colors[id - 1])
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
		
		get_node("/root/Main").call_deferred("add_child", player_instance)
	
	is_round_ongoing = true
	
func respawn_player(player_id, priority):
	var next_player = player_constructor(player_id, priority)
	next_player.first_spawn = false
	
	var next_player_orbs = next_player.get_node("Orbs")
	
	score[str(player_id)] = 0
	for stored_orb in stored_orbs[player_id - 1]:
		next_player_orbs.add_child(stored_orb)
		next_player_orbs.on_add_orb(stored_orb)
	
	stored_orbs[player_id - 1] = []
	
	get_node("/root/Main").call_deferred("add_child", next_player)

func update_score(id, new_score):
	get_node("/root/Main/Score").queue_redraw()
	
func inc_score(id):
	score[str(id)] += 1
	get_node("/root/Main/Score").queue_redraw()

func _process(delta):
	elapsed_time += delta
	
	if is_round_ongoing:
		for id in score.keys():
			if score[id] >= play_to:
				is_round_ongoing = false
				winner_id = int(id)
				get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
	
	if Input.is_action_just_pressed("exit_game"):
		is_round_ongoing = false
		get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")

func _on_RoundTimer_timeout():
	get_tree().change_scene_to_file("res://scenes/win_screen.tscn")
