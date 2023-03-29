extends Node2D


var score_radius
var epsilon = 0.1
var score_locations = {}

func _ready():
	var screen_size = get_viewport().size
	var min_screen_dimension = min(screen_size.x, screen_size.y)
	score_radius = min_screen_dimension * (sqrt(2) - 1) / 8
	
	var srr2 = score_radius * sqrt(2)
	score_locations = {
		"1": Vector2(srr2, srr2),
		"2": Vector2(srr2, screen_size.y - srr2),
		"3": Vector2(screen_size.x - srr2, screen_size.y - srr2),
		"4": Vector2(screen_size.x - srr2, srr2)
	}

func _draw():
	var theta = 2 * PI / Players.play_to
	for pn in Players.score:
		for i in range(0, Players.play_to):
			var color = Color(0.25, 0.25, 0.25, 0.5)
			if i + 1 <= Players.score[pn]:
				color = get_node("/root/Players").player_colors[int(pn) - 1]
			draw_arc(score_locations[pn], score_radius, \
			(i * theta) + epsilon, ((i + 1) * theta) - epsilon, 100, color, 10)
		
