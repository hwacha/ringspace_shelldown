extends Control

var registered_players = []

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
	
func get_input():
	for i in range(1, 5):
		for action in ["jump", "fast_fall", "use"]:
			if Input.is_action_just_pressed(action + "_p" + str(i)):
				set_registered_players(i)
				break

	if Input.is_action_just_pressed("ui_accept"):
		Players.set_player_ids(registered_players)
		get_tree().change_scene_to_file("scenes/main.tscn")
	
	if Input.is_action_just_pressed("debug_toggle_play"):
		var test_scene = preload("res://scenes/TestingStage.tscn").instantiate()
		test_scene.is_replay = false
		get_tree().get_root().add_child(test_scene)
		get_node("/root/OpeningScreen").queue_free()
		
	if Input.is_action_just_pressed("debug_toggle_pause"):
		var test_scene = preload("res://scenes/TestingStage.tscn").instantiate()
		test_scene.is_replay = true
		get_tree().get_root().add_child(test_scene)
		get_node("/root/OpeningScreen").queue_free()

func _process(delta):
	get_input()
	$Title.rotate(-0.1 * delta)
