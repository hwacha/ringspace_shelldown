extends Node2D

@export var num_segments: int = 16

var crust_ratio: float = 1.0 / 13.5 # 1 is the length of the screen

var screen_size

var outer_radius
var inner_radius
var midpoint_radius
var crust_size

var rng
@onready var crust_decay = get_node_or_null("../CrustDecay")

func _ready():
	var screen_width = ProjectSettings.get_setting("display/window/size/viewport_width")
	var screen_height = ProjectSettings.get_setting("display/window/size/viewport_height")
	screen_size = Vector2(screen_width, screen_height)
	outer_radius = min(screen_size.x, screen_size.y) / 2
	crust_size = outer_radius * crust_ratio
	inner_radius = outer_radius - crust_size
	
	midpoint_radius = (outer_radius + inner_radius) / 2
	
	var segment_d_theta = 2 * PI / num_segments
	
	var crust_segment_scene = load("res://scenes/CrustSegment.tscn")
	
	for i in range(num_segments):
		var crust_segment = crust_segment_scene.instantiate()
		crust_segment.set_name("segment_" + str(i))
		
		var crust_segment_theta = i * segment_d_theta
		
		crust_segment.transform.origin = midpoint_radius * Vector2(cos(crust_segment_theta), sin(crust_segment_theta))
		crust_segment.rotation += crust_segment_theta

		self.add_child(crust_segment)
	
	rng = RandomNumberGenerator.new()
	rng.randomize()
	
	get_parent().on_crust_ready()
