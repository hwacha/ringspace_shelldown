extends Control

func _ready():
	$WinText.text = "Player " + str(Players.winner_id) + " wins!"
	$Timer.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_Timer_timeout():
	get_tree().change_scene("res://scenes/opening_screen.tscn")
