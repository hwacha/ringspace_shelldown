extends Area2D

var id
var centroid

var traveling : bool = true
var claimed : bool = false

var rand = RandomNumberGenerator.new()

func _ready():
#	var lib = preload("res://animations/travel_to_destination.res").instantiate()
#	lib.add(preload("res://animations/travel_to_destination.res").instantiate())
#	$AnimationPlayer.add_animation_library("travel_to_destination", lib)
	rand.randomize()


func _process(_delta):
	pass

func _on_body_entered(body):
	if not (claimed or traveling or body.dead):
		$WaitingToTravel.stop()
		get_parent().call_deferred("remove_child", self)
		var new_orbs = body.get_node("Orbs")
		new_orbs.call_deferred("add_child", self)
		new_orbs.call_deferred("on_add_orb", self)

func set_new_destination():
	traveling = true
	var animation = $AnimationPlayer.get_animation("travel_to_destination_" + str(id))
	animation.track_set_key_value(0, 0, self.transform.origin)
	for i in range(1, 5):
		var r = 480 * sqrt(rand.randf())
		var theta = rand.randf() * 2 * PI
		
		var waypoint = r * Vector2(sin(theta), cos(theta)) + centroid
		
		animation.track_set_key_value(0, i, waypoint)
		$AnimationPlayer.play("travel_to_destination_" + str(id))

func _on_tree_entered():
	if get_parent().name == "Main":
		set_new_destination()


func _on_animation_player_animation_finished(_anim_name):
	traveling = false
	$WaitingToTravel.start()

func _on_waiting_to_travel_timeout():
	if not claimed:
		set_new_destination()
