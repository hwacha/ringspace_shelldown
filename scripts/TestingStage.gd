extends Node2D

var player
var file

var current_level : int = 0

@onready var input = $Input

@export var is_replay : bool

enum ReplayMode {
	PLAY,
	PAUSE
}

@export var replay_mode : ReplayMode = ReplayMode.PLAY

var lock = false

var frames_since_new_level = 0

var last_position = Vector2(0, 0)
var last_directional_input = Vector2(0, 0)

var next_position = null
var next_directional_input = null
var next_frame = -1
var next_level = -1

var win_condition : Callable = func (): return false
var loss_condition : Callable = func (): return false

func _ready():
	if is_replay:
		Players.lock_action = true
		if file == null:
			file = FileAccess.open("user://analytics.txt", FileAccess.READ)
	else:
		if file == null:
			file = FileAccess.open("user://analytics.txt", FileAccess.WRITE)
			
func _process(_delta):
	if lock:
		return

	if Input.is_action_just_pressed("ui_home"):
		if replay_mode == ReplayMode.PAUSE:
			replay_mode = ReplayMode.PLAY
		else:
			replay_mode = ReplayMode.PAUSE
		
	if is_replay:
		if Input.is_action_just_pressed("ui_focus_next"):
			frames_since_new_level += 1
			
		var line
		
		if next_frame == -1:
			line = file.get_line()

			if line.begins_with("LEVEL"):
				next_level = int(line.get_slice(":", 1))
				next_frame = int(line.get_slice(":", 2))
			else:
				next_position = str_to_var(line.get_slice(":", 0))
				next_directional_input = str_to_var(line.get_slice(":", 1))
				next_frame = int(line.get_slice(":", 2))

		if next_frame == frames_since_new_level and next_level != -1:
			current_level = next_level
			set_level(next_level, false)
			next_level = -1
			next_frame = -1
			
			line = file.get_line()
		
			next_position = str_to_var(line.get_slice(":", 0))
			next_directional_input = str_to_var(line.get_slice(":", 1))
			next_frame = int(line.get_slice(":", 2))
		
		if next_frame == frames_since_new_level and \
		(next_position != null or next_directional_input != null):
			player.transform.origin = next_position
			player.rotation = player.transform.origin.angle_to_point(Vector2(540, 540)) + (PI/2)
			input.visible = next_directional_input != Vector2(0, 0)
			input.transform.origin = player.transform.origin + (50 * next_directional_input)
			next_position = null
			next_directional_input = null
			next_frame = -1
	else:
		if win_condition.call():
			current_level += 1
			set_level(current_level, false)
		elif loss_condition.call():
			set_level(current_level, true)

		if lock:
			return
			
		var analog_h_movement = Input.get_axis("move_left_analog_p1", "move_right_analog_p1")
		var analog_v_movement = Input.get_axis("move_up_analog_p1", "move_down_analog_p1")
		var total_movement = Vector2(analog_h_movement, analog_v_movement)
		
		if player.transform.origin != last_position or total_movement != last_directional_input:
			file.store_line(var_to_str(player.transform.origin) + ":" + var_to_str(total_movement) + ":" + str(frames_since_new_level))
			file.flush()
			last_position = player.transform.origin
			last_directional_input = total_movement
		
	if not is_replay or replay_mode == ReplayMode.PLAY:
		frames_since_new_level += 1

func on_crust_ready():
	if file == null:
		if is_replay:
			file = FileAccess.open("user://analytics.txt", FileAccess.READ)
		else:
			file = FileAccess.open("user://analytics.txt", FileAccess.WRITE)
			
	if not is_replay:
		set_level(current_level, true)

func spawn_at_index(index):
	if player != null:
		$Players.remove_child(player)
		player.queue_free()
		player = null
		
	for crust_segment in $Crust.get_children():
		crust_segment.occupying_players = []

	player = Players.player_constructor(1, 2)
	player.first_spawn = false
	player.segment_spawn_index = index
	player.lock_physics = is_replay
	$Players.add_child(player)	

func set_level(n: int, needs_spawn: bool):
	if not is_replay:
		file.store_line("LEVEL:" + str(current_level) + ":" + str(frames_since_new_level))
	if n == 0:
		spawn_at_index(0)
		
		$Crust/segment_0.modulate = Color(5, 1, 1)
		$Crust/segment_8.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_8.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 1:
		if needs_spawn:
			spawn_at_index(8)
		$Crust/segment_0.modulate = Color(1, 1, 1)
		$Crust/segment_8.modulate = Color(5, 1, 1)
		$Crust/segment_12.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_12.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 2:
		if needs_spawn:
			spawn_at_index(12)
		$Crust/segment_8.modulate = Color(1, 1, 1)
		$Crust/segment_12.modulate = Color(5, 1, 1)
		$Crust/segment_4.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_4.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 3:
		if needs_spawn:
			spawn_at_index(4)
		$Crust/segment_12.modulate = Color(1, 1, 1)
		$Crust/segment_4.modulate = Color(5, 1, 1)
		$Crust/segment_2.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_2.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 4:
		if needs_spawn:
			spawn_at_index(2)
		$Crust/segment_4.modulate = Color(1, 1, 1)
		$Crust/segment_2.modulate = Color(5, 1, 1)
		$Crust/segment_5.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_5.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 5:
		if needs_spawn:
			spawn_at_index(5)
		$Crust/segment_2.modulate = Color(1, 1, 1)
		$Crust/segment_5.modulate = Color(5, 1, 1)
		$Crust/segment_10.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_10.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 6:
		if needs_spawn:
			spawn_at_index(10)
		$Crust/segment_5.modulate = Color(1, 1, 1)
		$Crust/segment_10.modulate = Color(5, 1, 1)
		$Crust/segment_7.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_7.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 7:
		if needs_spawn:
			spawn_at_index(7)
		$Crust/segment_10.modulate = Color(1, 1, 1)
		$Crust/segment_7.modulate = Color(5, 1, 1)
		$Crust/segment_13.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_13.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 8:
		if needs_spawn:
			spawn_at_index(13)
		$Crust/segment_7.modulate = Color(1, 1, 1)
		$Crust/segment_13.modulate = Color(5, 1, 1)
		$Crust/segment_11.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_11.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 9:
		if needs_spawn:
			spawn_at_index(11)
		$Crust/segment_13.modulate = Color(1, 1, 1)
		$Crust/segment_11.modulate = Color(5, 1, 1)
		$Crust/segment_1.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_1.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 10:
		if needs_spawn:
			spawn_at_index(1)
		$Crust/segment_11.modulate = Color(1, 1, 1)
		$Crust/segment_1.modulate = Color(5, 1, 1)
		$Crust/segment_0.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_0.occupying_players
		loss_condition = func():
			return Input.is_action_just_pressed("jump_p1")
	elif n == 11:
		if needs_spawn:
			spawn_at_index(0)
		$Crust/segment_1.modulate = Color(1, 1, 1)
		$Crust/segment_0.modulate = Color(5, 1, 1)
		$Crust/segment_8.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_8.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [0, 8] and \
				player.is_on_floor():
					return true
	elif n == 12:
		if needs_spawn:
			spawn_at_index(8)
		$Crust/segment_0.modulate = Color(1, 1, 1)
		$Crust/segment_8.modulate = Color(5, 1, 1)
		$Crust/segment_12.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_12.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [8, 12] and \
				player.is_on_floor():
					return true
	elif n == 13:
		if needs_spawn:
			spawn_at_index(12)
		$Crust/segment_8.modulate = Color(1, 1, 1)
		$Crust/segment_12.modulate = Color(5, 1, 1)
		$Crust/segment_4.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_4.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [12, 4] and \
				player.is_on_floor():
					return true
	elif n == 14:
		if needs_spawn:
			spawn_at_index(4)
		$Crust/segment_12.modulate = Color(1, 1, 1)
		$Crust/segment_4.modulate = Color(5, 1, 1)
		$Crust/segment_2.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_2.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [4, 2] and \
				player.is_on_floor():
					return true
	elif n == 15:
		if needs_spawn:
			spawn_at_index(2)
		$Crust/segment_4.modulate = Color(1, 1, 1)
		$Crust/segment_2.modulate = Color(5, 1, 1)
		$Crust/segment_5.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_5.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [2, 5] and \
				player.is_on_floor():
					return true
	elif n == 16:
		if needs_spawn:
			spawn_at_index(5)
		$Crust/segment_2.modulate = Color(1, 1, 1)
		$Crust/segment_5.modulate = Color(5, 1, 1)
		$Crust/segment_10.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_10.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [5, 10] and \
				player.is_on_floor():
					return true
	elif n == 17:
		if needs_spawn:
			spawn_at_index(10)
		$Crust/segment_5.modulate = Color(1, 1, 1)
		$Crust/segment_10.modulate = Color(5, 1, 1)
		$Crust/segment_7.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_7.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [10, 7] and \
				player.is_on_floor():
					return true
	elif n == 18:
		if needs_spawn:
			spawn_at_index(7)
		$Crust/segment_10.modulate = Color(1, 1, 1)
		$Crust/segment_7.modulate = Color(5, 1, 1)
		$Crust/segment_13.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_13.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [7, 13] and \
				player.is_on_floor():
					return true
	elif n == 19:
		if needs_spawn:
			spawn_at_index(13)
		$Crust/segment_7.modulate = Color(1, 1, 1)
		$Crust/segment_13.modulate = Color(5, 1, 1)
		$Crust/segment_11.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_11.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [13, 11] and \
				player.is_on_floor():
					return true
	elif n == 20:
		if needs_spawn:
			spawn_at_index(11)
		$Crust/segment_13.modulate = Color(1, 1, 1)
		$Crust/segment_11.modulate = Color(5, 1, 1)
		$Crust/segment_1.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_1.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [11, 1] and \
				player.is_on_floor():
					return true
	elif n == 21:
		if needs_spawn:
			spawn_at_index(1)
		$Crust/segment_11.modulate = Color(1, 1, 1)
		$Crust/segment_1.modulate = Color(5, 1, 1)
		$Crust/segment_0.modulate = Color(1, 5, 5)
		win_condition = func():
			return player.id in $Crust/segment_0.occupying_players
		loss_condition = func():
			for crust_segment in $Crust.get_children():
				if player.id in crust_segment.occupying_players and \
				not crust_segment.initial_segment_index in [1, 0] and \
				player.is_on_floor():
					return true
	else:
		if not is_replay:
			file = null
			lock = true
			get_tree().quit()

	frames_since_new_level = 0

func _on_tree_exiting():
	file = null
