extends Area2D

var claimed = false
var collectable = null : set = set_collectable

func _ready():
	$AnimationPlayer.play("spawn")

func _process(_delta):
	pass

func set_collectable(new_collectable):
	collectable = new_collectable
	$Sprite2D.texture = load("res://assets/" + new_collectable + ".png")

func _on_body_entered(body):
	if not claimed:
		get_node("../Powerups/Powerup" + str(body.id)).set_powerup(collectable)
		get_parent().call_deferred("remove_child", self)
		queue_free()
		claimed = true
