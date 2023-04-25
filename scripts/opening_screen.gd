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
	
	var master_sound = AudioServer.get_bus_index("Master")
	var is_muted = AudioServer.is_bus_mute(master_sound)
	if Input.is_action_just_pressed("settings_toggle_mute"):
		AudioServer.set_bus_mute(master_sound, not is_muted)
		
	$Settings.text = "[1] mute: " + str(is_muted) # + \
#					"\n[2] invert_controls: " + str(Players.settings["invert_controls"]) + \
#					"\n[3] segment_decay_enabled: " + str(Players.settings["segment_decay_enabled"])

	if Input.is_action_just_pressed("ui_accept"):
		Players.set_player_ids(registered_players)
		get_tree().change_scene_to_file("scenes/main.tscn")
	

func _process(delta):
	get_input()
