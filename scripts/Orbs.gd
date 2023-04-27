extends Node2D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	rotate(delta)
	pass

func on_add_orb(new_orb):
	new_orb.claimed = true
	var orbs = get_children()
	var num_orbs = orbs.size()
	
	var r = 40.0
	
	var d_theta = 2 * PI / num_orbs
	var theta = 0
	for orb in orbs:
		orb.transform.origin = r * Vector2(cos(theta), sin(theta))
		theta += d_theta
	var player_id = get_parent().id
	Players.inc_score(player_id)
