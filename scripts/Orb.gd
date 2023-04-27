extends Area2D

var id
var centroid

var traveling : bool = true
var claimed : bool = false

var rand = RandomNumberGenerator.new()

func _ready():
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
	var animation = $AnimationPlayer.get_animation("custom/travel_to_destination")
	animation.track_set_key_value(0, 0, self.transform.origin)
	for i in range(1, 5):
		var r = 480 * sqrt(rand.randf())
		var theta = rand.randf() * 2 * PI
		
		var waypoint = r * Vector2(sin(theta), cos(theta)) + centroid
		
		animation.track_set_key_value(0, i, waypoint)
		$AnimationPlayer.play("custom/travel_to_destination")
	
	$WaitingToTravel.start()

func create_animation():
	var anim = Animation.new()
	anim.length = 2.0
	var track_index = anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_interpolation_type(track_index, Animation.INTERPOLATION_CUBIC)
	anim.track_set_path(track_index, ".:position")
	
	for t in range(5):
		anim.track_insert_key(track_index, t * 0.5, Vector2(0, 0))
	
	var lib = AnimationLibrary.new()
	lib.add_animation("travel_to_destination", anim)
	
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	anim_player.add_animation_library("custom", lib)
	
	add_child(anim_player)

func _on_tree_entered():
	if get_parent().name == "Main":
		create_animation()
	else:
		set_new_destination()

func _on_animation_player_animation_finished(_anim_name):
	traveling = false

func _on_waiting_to_travel_timeout():
	if not claimed:
		set_new_destination()

func _on_child_entered_tree(node):
	set_new_destination()
