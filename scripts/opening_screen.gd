extends Control

var registered_players = []

var t = 0

func _ready():
	for i in range(4):
		var joy_name = Input.get_joy_name(i)
		var path = "res://assets/"
		
		var some_controller_matched = true
		
		if joy_name == "PS4 Controller":
			path += "PS4/"
		elif joy_name == "PS5 Controller":
			path += "PS5/"
		elif joy_name.begins_with("Xbox"):
			path += "Xbox Series/"
		elif joy_name == "Joy-Con (L)":
			path += "Switch_Left/"
		elif joy_name == "Joy-Con (R)":
			path += "Switch_Right/"
		else:
			path += "Keys/" + str(i) + "/"
			some_controller_matched = false
		
		var sprite = load(path + "Bottom_Action.png") if some_controller_matched else load(path + "Up.png")
		var col = $PlayerRegister/Left if i < 2 else $PlayerRegister/Right
		col.get_node("P" + str(i + 1) + "/Unregistered/Container/Sprite2D").texture = sprite
	
func set_registered_players(id):
	var container = $PlayerRegister/Left if id in [1, 2] else $PlayerRegister/Right
	if id in registered_players:
		registered_players.erase(id)
		container.get_node("P" + str(id) + "/Registered").set_visible(false)
		container.get_node("P" + str(id) + "/Unregistered").set_visible(true)
	else:
		registered_players.push_back(id)
		container.get_node("P" + str(id) + "/Unregistered").set_visible(false)
		container.get_node("P" + str(id) + "/Registered").set_visible(true)
	
	var has_one_player = registered_players.size() > 0
	if not $PlayerRegister/Center/StartPrompt.visible and has_one_player:
		t = 0
	$PlayerRegister/Center/StartPrompt.visible = registered_players.size() > 0
	
func get_input():
	for i in range(1, 5):
		for action in ["jump", "fast_fall", "use"]:
			if Input.is_action_just_pressed(action + "_p" + str(i)):
				set_registered_players(i)
				break
	
	if Input.is_action_just_pressed("ui_accept"):
		if registered_players.size() > 0:
			Players.set_player_ids(registered_players)
			get_tree().change_scene_to_file("scenes/main.tscn")
	
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
	get_input()
#	for c in Input.get_connected_joypads():
#		print(Input.get_joy_name(c))

	$Title.rotate(-0.1 * delta)
	
	var flash_t = 1 + cos(t * 3)
	$PlayerRegister/Center/StartPrompt/CenterContainer/RichTextLabel.modulate.a = flash_t
	$PlayerRegister/Center/StartPrompt/CenterContainer/Sprite2D.modulate.a = flash_t
	t += delta
