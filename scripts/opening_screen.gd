extends Control

var registered_players = []

var t = 0

var time_start_pressed : float = 0
var how_to_threshold : float = 1.5

func _ready():
	pass
	
func set_registered_players(id):
	if id in registered_players:
		registered_players.erase(id)
		get_node("P" + str(id) + "Registered").set_visible(false)
		get_node("P" + str(id) + "Unregistered").set_visible(true)
	else:
		registered_players.push_back(id)
		get_node("P" + str(id) + "Unregistered").set_visible(false)
		get_node("P" + str(id) + "Registered").set_visible(true)
	
	var has_one_player = registered_players.size() > 0
	if not $StartPrompt.visible and has_one_player:
		t = 0
	$StartPrompt.visible = registered_players.size() > 0
	
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
		if time_start_pressed < how_to_threshold:
			if registered_players.size() > 0:
				get_tree().change_scene_to_file("scenes/main.tscn")
				Players.set_player_ids(registered_players)
	
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
	$StartPrompt/RichTextLabel2.visible_ratio = 1 - (time_start_pressed / how_to_threshold)
	get_input(delta)
	$Title.rotate(-0.1 * delta)
	
	$StartPrompt/RichTextLabel.modulate.a = 1 + cos(t * 3)
	t += delta
