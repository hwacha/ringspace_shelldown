extends Control

var registered_players = []

var t = 0

var time_start_pressed : float = 0
var start_threshold : float = 0.5
var how_to_threshold : float = 1.5

func _ready():
	pass
	
func set_registered_players(id):
	if id in registered_players:
		registered_players.erase(id)
		$PlayerRegister.get_node("P" + str(id) + "/Registered").set_visible(false)
		$PlayerRegister.get_node("P" + str(id) + "/Unregistered").set_visible(true)
	else:
		registered_players.push_back(id)
		$PlayerRegister.get_node("P" + str(id) + "/Unregistered").set_visible(false)
		$PlayerRegister.get_node("P" + str(id) + "/Registered").set_visible(true)
	
	var has_one_player = registered_players.size() > 0
	if not $PlayerRegister/TopCenter/StartPrompt.visible and has_one_player:
		t = 0
	$PlayerRegister/TopCenter/StartPrompt.visible = registered_players.size() > 0
	$PlayerRegister/BottomCenter/HowToPrompt.visible = registered_players.size() > 0
	
func get_input(delta):
	if Input.is_action_pressed("ui_accept"):
		if registered_players.size() > 0:
			time_start_pressed += delta
	else:
		for i in range(1, 5):
			for action in ["jump", "fast_fall", "use"]:
				if Input.is_action_just_pressed(action + "_p" + str(i)):
					set_registered_players(i)
					break
		
	if time_start_pressed >= how_to_threshold:
		Players.set_player_ids(registered_players)
		get_tree().change_scene_to_file("res://scenes/how_to.tscn")
		return
	
	if Input.is_action_just_released("ui_accept"):
		if time_start_pressed < start_threshold:
			if registered_players.size() > 0:
				get_tree().change_scene_to_file("scenes/main.tscn")
				Players.set_player_ids(registered_players)
		else:
			time_start_pressed = 0
	
#	if Input.is_action_just_pressed("debug_toggle_play"):
#		var test_scene = preload("res://scenes/TestingStage.tscn").instantiate()
#		test_scene.is_replay = false
#		get_tree().get_root().add_child(test_scene)
#		get_node("/root/OpeningScreen").queue_free()
#
#	if Input.is_action_just_pressed("debug_toggle_pause"):
#		var test_scene = preload("res://scenes/TestingStage.tscn").instantiate()
#		test_scene.is_replay = true
#		get_tree().get_root().add_child(test_scene)
#		get_node("/root/OpeningScreen").queue_free()

func _process(delta):
	var press_ratio = (time_start_pressed - start_threshold) / (how_to_threshold - start_threshold)
	$PlayerRegister/BottomCenter/HowToPrompt/ProgressBar.modulate.a = 0.0 if time_start_pressed < start_threshold else 0.7
	$PlayerRegister/BottomCenter/HowToPrompt/ProgressBar.value = 100 * press_ratio

	get_input(delta)
	$Title.rotate(-0.1 * delta)
	
	var flash_t = 1 + cos(t * 3)
	$PlayerRegister/TopCenter/StartPrompt/RichTextLabel.modulate.a = flash_t
	$PlayerRegister/TopCenter/StartPrompt/Sprite2D.modulate.a = flash_t
	t += delta
