extends Area2D

var claimed = false
var collectable = null : set = set_collectable

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func set_collectable(new_collectable):
	collectable = new_collectable
	$Sprite2D.texture = load("res://assets/" + new_collectable + ".png")

func _on_body_entered(body):
	if body.spawning:
		return

	get_node("../Powerups/Powerup" + str(body.id)).set_powerup(collectable)
	claimed = true
	get_parent().call_deferred("remove_child", self)
	queue_free()
