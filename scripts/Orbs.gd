extends Node2D

var r : float = 40.0
var rotation_speed : float = 1.0

var dir

func _ready():
	if Players.star_direction != null:
		dir = Players.star_direction

func _process(delta):
	rotate(dir * rotation_speed * delta)

func on_add_orb(new_orb):
	new_orb.claimed = true
	var orbs = get_children()
	var num_orbs = orbs.size()
	
	var d_theta = 2 * PI / num_orbs
	var theta = 0
	for orb in orbs:
		orb.transform.origin = r * Vector2(cos(theta), sin(theta))
		theta += d_theta
