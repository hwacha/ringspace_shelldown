extends Node2D


var score_radius
var epsilon = 0.05
var score_locations = {}

func _ready():
	var screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var screen_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	var screen_size = Vector2(screen_width, screen_height)
	var min_screen_dimension = min(screen_size.x, screen_size.y)
	score_radius = min_screen_dimension / (6 + 4 * sqrt(2))
	
	score_locations = {
		"1": Vector2(score_radius, score_radius),
		"2": Vector2(score_radius, screen_size.y - score_radius),
		"3": Vector2(screen_size.x - score_radius, screen_size.y - score_radius),
		"4": Vector2(screen_size.x - score_radius, score_radius)
	}
	
	for id in Players.starting_ids:
		#remove hotjoin text
		var hotjoin_text = get_node("../HotjoinText/" + str(id))
		hotjoin_text.get_parent().remove_child(hotjoin_text)
		hotjoin_text.queue_free()
		#add powerup
		var powerup = preload("res://scenes/Powerup.tscn").instantiate()
		powerup.transform.origin = score_locations[str(id)]
		powerup.name += str(id)
		powerup.modulate = Players.player_colors[id - 1].lightened(0.5)
		get_node("../Powerups").add_child(powerup)
	
	
func _process(_delta):
	pass

func _draw():
	var theta = 2 * PI / Players.play_to
	for pn in Players.score:
		draw_arc(score_locations[pn], score_radius * 0.5, 0, 2 * PI, 100, Players.player_colors[int(pn) - 1].darkened(0.4) - Color(0, 0, 0, 0.5), 3) 
		var theta_offset = 7 * PI / 4 + theta - (PI / 2 * int(pn))
		for i in range(0, Players.play_to):
			var color = Color(0.094, 0.161, 0.204, 0.5)
			if i + 1 <= Players.score[pn]:
				color = Players.player_colors[int(pn) - 1]
			draw_arc(score_locations[pn], score_radius * 11 / 16, \
			(i * theta) + theta_offset + epsilon, ((i + 1) * theta) + theta_offset - epsilon, 100, color, score_radius / 4)
		
