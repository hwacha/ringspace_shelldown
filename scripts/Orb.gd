extends Area2D

var id

var claimed : bool = false

func _ready():
	pass # Replace with function body.

func _process(_delta):
	pass

func _on_body_entered(body):
	if not claimed:
		get_parent().call_deferred("remove_child", self)
		var new_orbs = body.get_node("Orbs")
		new_orbs.call_deferred("add_child", self)
		new_orbs.call_deferred("on_add_orb", self)
