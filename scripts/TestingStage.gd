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
	
	$PlaybackStatus.visible = is_replay
	
func _process(_delta):
	if lock:
		return

	if is_replay and \
	(Input.is_action_just_pressed("debug_toggle_play") or \
	Input.is_action_just_pressed("debug_toggle_pause")):
		if replay_mode == ReplayMode.PAUSE:
			replay_mode = ReplayMode.PLAY
			$PlaybackStatus.text = "▶️"
		else:
			replay_mode = ReplayMode.PAUSE
			$PlaybackStatus.text = "⏸️"
		
	if is_replay:
		if replay_mode == ReplayMode.PAUSE and Input.is_action_just_pressed("ui_focus_next"):
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
			if lock:
				return
			
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
	
func player_on_platform(platform_index):
	return func () -> bool:
		if not player.id in $Crust.get_node("segment_" + str(platform_index)).occupying_players:
			return false
		for crust_segment in $Crust.get_children():
			if crust_segment.initial_segment_index != platform_index and player.id in crust_segment.occupying_players:
				return false
		return player.is_on_floor()
		
func player_in_air():
	return player.frames_in_air > 8
	
func player_on_platform_other_than(source_index, destination_index):
	return func () -> bool:
		for crust_segment in $Crust.get_children():
			if player.id in crust_segment.occupying_players and \
			not crust_segment.initial_segment_index in [source_index, destination_index] and \
			player.is_on_floor():
				return true
		return false
		

func set_level(n: int, needs_spawn: bool):
	if not is_replay:
		file.store_line("LEVEL:" + str(current_level) + ":" + str(frames_since_new_level))
	if n == 0:
		spawn_at_index(0)
		$Crust/segment_0.modulate = Color(5, 1, 1)
		$Crust/segment_8.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(8)
		loss_condition = player_in_air
	elif n == 1:
		if needs_spawn:
			spawn_at_index(8)
		$Crust/segment_0.modulate = Color(1, 1, 1)
		$Crust/segment_8.modulate = Color(5, 1, 1)
		$Crust/segment_12.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(12)
		loss_condition = player_in_air
	elif n == 2:
		if needs_spawn:
			spawn_at_index(12)
		$Crust/segment_8.modulate = Color(1, 1, 1)
		$Crust/segment_12.modulate = Color(5, 1, 1)
		$Crust/segment_4.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(4)
		loss_condition = player_in_air
	elif n == 3:
		if needs_spawn:
			spawn_at_index(4)
		$Crust/segment_12.modulate = Color(1, 1, 1)
		$Crust/segment_4.modulate = Color(5, 1, 1)
		$Crust/segment_2.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(2)
		loss_condition = player_in_air
	elif n == 4:
		if needs_spawn:
			spawn_at_index(2)
		$Crust/segment_4.modulate = Color(1, 1, 1)
		$Crust/segment_2.modulate = Color(5, 1, 1)
		$Crust/segment_5.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(5)
		loss_condition = player_in_air
	elif n == 5:
		if needs_spawn:
			spawn_at_index(5)
		$Crust/segment_2.modulate = Color(1, 1, 1)
		$Crust/segment_5.modulate = Color(5, 1, 1)
		$Crust/segment_10.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(10)
		loss_condition = player_in_air
	elif n == 6:
		if needs_spawn:
			spawn_at_index(10)
		$Crust/segment_5.modulate = Color(1, 1, 1)
		$Crust/segment_10.modulate = Color(5, 1, 1)
		$Crust/segment_7.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(7)
		loss_condition = player_in_air
	elif n == 7:
		if needs_spawn:
			spawn_at_index(7)
		$Crust/segment_10.modulate = Color(1, 1, 1)
		$Crust/segment_7.modulate = Color(5, 1, 1)
		$Crust/segment_13.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(13)
		loss_condition = player_in_air
	elif n == 8:
		if needs_spawn:
			spawn_at_index(13)
		$Crust/segment_7.modulate = Color(1, 1, 1)
		$Crust/segment_13.modulate = Color(5, 1, 1)
		$Crust/segment_11.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(11)
		loss_condition = player_in_air
	elif n == 9:
		if needs_spawn:
			spawn_at_index(11)
		$Crust/segment_13.modulate = Color(1, 1, 1)
		$Crust/segment_11.modulate = Color(5, 1, 1)
		$Crust/segment_1.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(1)
		loss_condition = player_in_air
	elif n == 10:
		if needs_spawn:
			spawn_at_index(1)
		$Crust/segment_11.modulate = Color(1, 1, 1)
		$Crust/segment_1.modulate = Color(5, 1, 1)
		$Crust/segment_0.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(0)
		loss_condition = player_in_air
	elif n == 11:
		$Task.text = "[center]Go to the blue platform by [color=cyan]only[/color] jumping[/center]"
		if needs_spawn:
			spawn_at_index(0)
		$Crust/segment_1.modulate = Color(1, 1, 1)
		$Crust/segment_0.modulate = Color(5, 1, 1)
		$Crust/segment_8.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(8)
		loss_condition = player_on_platform_other_than(0, 8)
	elif n == 12:
		if needs_spawn:
			spawn_at_index(8)
		$Crust/segment_0.modulate = Color(1, 1, 1)
		$Crust/segment_8.modulate = Color(5, 1, 1)
		$Crust/segment_12.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(12)
		loss_condition = player_on_platform_other_than(8, 12)
	elif n == 13:
		if needs_spawn:
			spawn_at_index(12)
		$Crust/segment_8.modulate = Color(1, 1, 1)
		$Crust/segment_12.modulate = Color(5, 1, 1)
		$Crust/segment_4.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(4)
		loss_condition = player_on_platform_other_than(12, 4)
	elif n == 14:
		if needs_spawn:
			spawn_at_index(4)
		$Crust/segment_12.modulate = Color(1, 1, 1)
		$Crust/segment_4.modulate = Color(5, 1, 1)
		$Crust/segment_2.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(2)
		loss_condition = player_on_platform_other_than(4, 2)
	elif n == 15:
		if needs_spawn:
			spawn_at_index(2)
		$Crust/segment_4.modulate = Color(1, 1, 1)
		$Crust/segment_2.modulate = Color(5, 1, 1)
		$Crust/segment_5.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(5)
		loss_condition = player_on_platform_other_than(2, 5)
	elif n == 16:
		if needs_spawn:
			spawn_at_index(5)
		$Crust/segment_2.modulate = Color(1, 1, 1)
		$Crust/segment_5.modulate = Color(5, 1, 1)
		$Crust/segment_10.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(10)
		loss_condition = player_on_platform_other_than(5, 10)
	elif n == 17:
		if needs_spawn:
			spawn_at_index(10)
		$Crust/segment_5.modulate = Color(1, 1, 1)
		$Crust/segment_10.modulate = Color(5, 1, 1)
		$Crust/segment_7.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(7)
		loss_condition = player_on_platform_other_than(10, 7)
	elif n == 18:
		if needs_spawn:
			spawn_at_index(7)
		$Crust/segment_10.modulate = Color(1, 1, 1)
		$Crust/segment_7.modulate = Color(5, 1, 1)
		$Crust/segment_13.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(13)
		loss_condition = player_on_platform_other_than(7, 13)
	elif n == 19:
		if needs_spawn:
			spawn_at_index(13)
		$Crust/segment_7.modulate = Color(1, 1, 1)
		$Crust/segment_13.modulate = Color(5, 1, 1)
		$Crust/segment_11.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(11)
		loss_condition = player_on_platform_other_than(13, 11)
	elif n == 20:
		if needs_spawn:
			spawn_at_index(11)
		$Crust/segment_13.modulate = Color(1, 1, 1)
		$Crust/segment_11.modulate = Color(5, 1, 1)
		$Crust/segment_1.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(1)
		loss_condition = player_on_platform_other_than(11, 1)
	elif n == 21:
		if needs_spawn:
			spawn_at_index(1)
		$Crust/segment_11.modulate = Color(1, 1, 1)
		$Crust/segment_1.modulate = Color(5, 1, 1)
		$Crust/segment_0.modulate = Color(1, 5, 5)
		win_condition = player_on_platform(0)
		loss_condition = player_on_platform_other_than(1, 0)
	else:
		file = null
		lock = true
		get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")
		get_tree().get_root().remove_child(self)
		self.queue_free()

	frames_since_new_level = 0

func _on_tree_exiting():
	file = null
