extends Node2D

var r : float = 40.0
var rotation_speed : float = 1.0

func _ready():
	pass

func _process(delta):
	rotate(Players.star_direction * rotation_speed * delta)

func on_add_orb(new_orb):
	new_orb.claimed = true
	var orbs = get_children()
	var num_orbs = orbs.size()
	
	var d_theta = 2 * PI / num_orbs
	var theta = 0
	for orb in orbs:
		orb.transform.origin = r * Vector2(cos(theta), sin(theta))
		theta += d_theta
