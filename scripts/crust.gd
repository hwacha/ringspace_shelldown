extends Node2D

@export var num_segments: int = 16
@export var colliders_per_segment: int = 5
@export var crust_ratio: float = 1.0 / 15 # 1 is the length of the screen

var screen_size

var outer_radius
var inner_radius
var midpoint_radius
var crust_size

var rng
@onready var crust_decay = get_node("../CrustDecay")
@onready var round_text = get_node("../RoundText")

# decay time
@export var minimum_decay_period: float = 3.0  # seconds
var decay_constant

func _ready():
	Players.lock_action = true
	decay_constant = pow(minimum_decay_period / crust_decay.wait_time, 1.0/num_segments)

	var screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var screen_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	screen_size = Vector2(screen_width, screen_height)
	outer_radius = min(screen_size.x, screen_size.y) / 2
	crust_size = outer_radius * crust_ratio
	inner_radius = outer_radius - crust_size
	
	midpoint_radius = (outer_radius + inner_radius) / 2
	
	var segment_d_theta = 2 * PI / num_segments
	
	var num_colliders = num_segments * colliders_per_segment
	var collider_d_theta = segment_d_theta / colliders_per_segment
	
	var crust_segment_scene = load("res://scenes/CrustSegment.tscn")
	
	var anim = get_node("../Camera2D/AnimationPlayer")
	anim.play("zoom_out")
	
	for i in range(num_segments):
		var crust_segment = crust_segment_scene.instantiate()
		crust_segment.set_name("segment_" + str(i))
		crust_segment.midpoint_radius = midpoint_radius
		crust_segment.crust_size = crust_size
		crust_segment.num_segments = num_segments
		crust_segment.colliders_per_segment = colliders_per_segment
		crust_segment.arc_index = i
		var crust_segment_theta = i * segment_d_theta
		
		for j in range(colliders_per_segment):
			var cord = RectangleShape2D.new()
			cord.size = Vector2(PI * 2 * midpoint_radius / num_colliders, crust_size)
			var collider = CollisionShape2D.new()
			collider.shape = cord
			
			var collider_theta = (i * colliders_per_segment + j) * collider_d_theta
			
			collider.rotation = collider_theta + (PI / 2)
			collider.transform.origin = midpoint_radius * Vector2(cos(collider_theta), sin(collider_theta))
			
			crust_segment.add_child(collider)
		
		self.add_child(crust_segment)
	
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	get_node("/root/Players").spawn_players()
	
	if Players.settings["segment_decay_enabled"]:
		crust_decay.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_CrustDecay_timeout():
	if Players.settings["segment_decay_enabled"]:
		var rand = rng.randi_range(0, get_child_count() - 1)
		var segment = get_child(rand)
		if segment != null:
			segment.destroy()
			crust_decay.set_wait_time(crust_decay.wait_time * decay_constant)
			crust_decay.start()


func _on_animation_player_animation_finished(anim_name):
	Players.lock_action = false
	round_text.text = "[center]GO[/center]"
	round_text.modulate.a = 255
	round_text.get_node("Go").start()

func _on_go_timeout():
	round_text.set_visible(false)
