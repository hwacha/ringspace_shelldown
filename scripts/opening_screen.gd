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
	

func _process(delta):
	get_input()
	$Title.rotate(-0.1 * delta)
