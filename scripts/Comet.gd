extends Area2D

var centroid
var dir_sign
var player_who_shot : set = _set_player_who_shot
var player_who_shot_id : int

@export var speed : float = 1000.0

func _set_player_who_shot(player):
	player_who_shot = player
	player_who_shot_id = player.id
	$Sprite2D.texture = load("res://assets/comet_" + Players.player_names[player.id - 1] + ".png")

# Called when the node enters the scene tree for the first time.
func _ready():
	$Decay.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var diff = self.transform.origin - centroid
	
	var perp_velocity = diff.rotated(dir_sign * (PI / 2 + 0.01)).normalized() * delta * speed
	rotation = perp_velocity.angle() + PI
	self.transform.origin += perp_velocity


func _on_decay_timeout():
	get_parent().remove_child(self)
	self.queue_free()


func _on_body_entered(body):
	if body == player_who_shot or body.id == player_who_shot_id or body.invulnerable:
		return
	elif body.shields.size() > 0 and not body.dead:
		player_who_shot = body
		dir_sign *= -1
		body.remove_shields(1)
	else:
		body.killer = player_who_shot
		body.killer_id = player_who_shot_id
		body.die()


func _on_area_entered(area):
	assert(area is NeutralOrbCapsule)
	# player is next orb claimant
	for orb in area.get_node("Orbs").get_children():
		orb.next_claimant = player_who_shot
		orb.next_claimant_id = player_who_shot_id
	area.call_deferred("release_orbs_and_destruct")
