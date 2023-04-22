extends Node2D

@export var num_segments: int = 16
var crust_ratio: float = 1.0 / 10 # 1 is the length of the screen

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
	
	var crust_segment_scene = load("res://scenes/CrustSegment.tscn")
	
	var anim = get_node("../Camera2D/AnimationPlayer")
	anim.play("zoom_out")
	
	for i in range(num_segments):
		var crust_segment = crust_segment_scene.instantiate()
		crust_segment.arc_index = i
		crust_segment.set_name("segment_" + str(i))
		
		var crust_segment_theta = i * segment_d_theta
		
		crust_segment.transform.origin = midpoint_radius * Vector2(cos(crust_segment_theta), sin(crust_segment_theta))
		crust_segment.rotation += crust_segment_theta
		self.add_child(crust_segment)
	
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	get_node("/root/Players").spawn_players()

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


func _on_round_begin():
	Players.lock_action = false
	if Players.settings["segment_decay_enabled"]:
		crust_decay.start()
