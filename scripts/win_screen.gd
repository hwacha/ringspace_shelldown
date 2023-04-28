extends Control

func sort_by_value(a, b):
	return a[1] > b[1]

func _ready():
	var arr = []
	for id in Players.score.keys():
		arr.push_back([id, Players.score[id]])
		
	arr.sort_custom(sort_by_value)
	
	print(arr)
	
	var places = ["1st", "2nd", "3rd", "4th"]
	var place_counter = 0
	var last_score = 1000000
	for i in range(arr.size()):
		var text = get_node("Text" + str(i + 1))
		text.modulate = Players.player_colors[int(arr[i][0]) - 1]
		
		var cur_score = arr[i][1]
		if cur_score < last_score:
			last_score = cur_score
			place_counter = i

		text.text = places[place_counter] + " " + Players.player_names[int(arr[i][0]) - 1] + " - " + str(cur_score)
		

	$Timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")
	Players.initialize_for_new_round()
