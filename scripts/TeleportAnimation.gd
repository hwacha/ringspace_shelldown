extends Node2D

var player : Player
var color : Color
var source : Vector2
var destination : Vector2

var animation_player : AnimationPlayer

func _ready():
	color = player.get_node("DeathParticles").modulate + Color(0.2, 0.2, 0.2, -0.3)
	var animation = Animation.new()
	animation.length = 0.5
	var track_index_source = animation.add_track(Animation.TYPE_VALUE)
	var track_index_destination = animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track_index_source, ".:source")
	animation.track_set_path(track_index_destination, ".:source")
	
	animation.track_insert_key(track_index_destination, 0.0, source)
	animation.track_insert_key(track_index_destination, 0.5 * animation.length, destination)
	
	animation.track_insert_key(track_index_source, 0.5 * animation.length, source)
	animation.track_insert_key(track_index_source, animation.length, destination)
	
	var lib = AnimationLibrary.new()
	lib.add_animation("teleport", animation)
	animation_player = AnimationPlayer.new()
	animation_player.add_animation_library("custom", lib)
	
	animation_player.play("custom/teleport")
	animation_player.animation_finished.connect(_on_animation_finished)

	add_child(animation_player)

func _process(_delta):
	queue_redraw()
	
func _draw():
	draw_line(source, destination, color, 8)

func _on_animation_finished(_anim):
	player.transform.origin = destination
	player.visible = true
	player.lock_physics = false
