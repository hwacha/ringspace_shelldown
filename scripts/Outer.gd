extends Node2D

func _draw():
	draw_circle(Vector2(0,0), get_parent().outer_radius, Color(0.25, 0.25, 0.25))
