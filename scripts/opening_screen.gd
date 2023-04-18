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
		if Input.is_action_just_pressed("jump_p" + str(i)):
			set_registered_players(i)
			
	var players = get_node("/root/Players")
	
	if Input.is_action_just_pressed("settings_toggle_fast_fall"):
		players.settings["fast_fall_enabled"] = not players.settings["fast_fall_enabled"]
	if Input.is_action_just_pressed("settings_invert_controls"):
		players.settings["invert_controls"] = not players.settings["invert_controls"]
	if Input.is_action_just_pressed("settings_toggle_segment_decay"):
		players.settings["segment_decay_enabled"] = not players.settings["segment_decay_enabled"]
		
	$Settings.text = "[1] fast_fall_enabled: " + str(Players.settings["fast_fall_enabled"]) + \
					"\n[2] invert_controls: " + str(Players.settings["invert_controls"]) + \
					"\n[3] segment_decay_enabled: " + str(Players.settings["segment_decay_enabled"])
	
	if Input.is_action_just_pressed("ui_accept"):
		Players.set_player_ids(registered_players)
		get_tree().change_scene_to_file("scenes/main.tscn")

func _process(delta):
	get_input()
