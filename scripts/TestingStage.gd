extends Node2D

var player
var file

var current_level : int = 0

@onready var input = $Input

@export var is_replay : bool

var frames_since_new_level = 0

var last_position = Vector2(0, 0)
var last_directional_input = Vector2(0, 0)

var next_position = null
var next_directional_input = null
var next_frame = -1

func _ready():
	if is_replay:
		Players.lock_action = true
		file = FileAccess.open("user://analytics.txt", FileAccess.READ)
	else:
		file = FileAccess.open("user://analytics.txt", FileAccess.WRITE)
func _process(_delta):
	if is_replay:
		if next_frame == -1:
			var line = file.get_line()

			if line.begins_with("LEVEL"):
				var level = int(line.right(1))
				set_level(level)
			else:
				next_position = str_to_var(line.get_slice(":", 0))
				next_directional_input = str_to_var(line.get_slice(":", 1))
				next_frame = int(line.get_slice(":", 2))

		if next_frame == frames_since_new_level:
			player.transform.origin = next_position
			player.rotation = player.transform.origin.angle_to_point(Vector2(540, 540)) + (PI/2)
			input.visible = next_directional_input != Vector2(0, 0)
			input.transform.origin = player.transform.origin + (50 * next_directional_input)
			next_position = null
			next_directional_input = null
			next_frame = -1
	else:
		var analog_h_movement = Input.get_axis("move_left_analog_p1", "move_right_analog_p1")
		var analog_v_movement = Input.get_axis("move_up_analog_p1", "move_down_analog_p1")
		var total_movement = Vector2(analog_h_movement, analog_v_movement)
		
		if player.transform.origin != last_position or total_movement != last_directional_input:
			file.store_line(var_to_str(player.transform.origin) + ":" + var_to_str(total_movement) + ":" + str(frames_since_new_level))
			file.flush()
			last_position = player.transform.origin
			last_directional_input = total_movement
		
	
	frames_since_new_level += 1
	

func on_crust_ready():
	if file == null:
		if is_replay:
			file = FileAccess.open("user://analytics.txt", FileAccess.READ)
		else:
			file = FileAccess.open("user://analytics.txt", FileAccess.WRITE)
	set_level(current_level)

func set_level(n: int):
	if not is_replay:
		file.store_line("LEVEL")
	if n == 0:
		player = Players.player_constructor(1, 2)
		player.first_spawn = false
		player.segment_spawn_index = 0
		player.lock_physics = true
		$Players.add_child(player)
		

	frames_since_new_level = 0

func _on_tree_exiting():
	file = null
