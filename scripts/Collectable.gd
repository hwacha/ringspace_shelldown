extends Area2D

var collectable = null : set = set_collectable

var claimants = []

func _ready():
	$AnimationPlayer.play("spawn")

func _process(_delta):
	if claimants.size() > 0:
		var claimant_id = claimants.pick_random()
		get_node("../Powerups/Powerup" + str(claimant_id)).set_powerup(collectable)
		get_parent().call_deferred("remove_child", self)
		queue_free()

func set_collectable(new_collectable):
	collectable = new_collectable
	$Sprite2D.texture = load("res://assets/" + new_collectable + ".png")

func _on_body_entered(body):
	claimants.push_back(body.id)
