extends Control



func _ready():
	self.modulate = Players.player_colors[Players.winner_id - 1]
	$WinText.text = Players.player_names[Players.winner_id - 1] + " wins!"
	$Timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	get_tree().change_scene_to_file("res://scenes/opening_screen.tscn")
	Players.initialize_for_new_round()
