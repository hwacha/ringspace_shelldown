extends Node2D

@export var num_segments: int = 16

var segments_to_keep = [
	0, 3, 4, 5, 8, 9, 10, 11, 12, 13, 14, 15
]

var num_segments_remaining_at_end

var segments_to_decay

var crust_ratio: float = 1.0 / 13.5 # 1 is the length of the screen

var screen_size

var outer_radius
var inner_radius
var midpoint_radius
var crust_size

var rng
@onready var crust_decay = get_node_or_null("../CrustDecay")

# decay time
@export var minimum_decay_period: float = 3.0  # seconds
var decay_constant

func _ready():
	if crust_decay != null:
		if Players.star_direction == 1:
			segments_to_keep.push_back(2)
			segments_to_keep.push_back(7)
		else:
			segments_to_keep.push_back(1)
			segments_to_keep.push_back(6)

		num_segments_remaining_at_end = segments_to_keep.size()

		segments_to_decay = []
		for ind in range(num_segments):
			if not ind in segments_to_keep:
				segments_to_decay.push_back(ind)

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
	

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_CrustDecay_timeout():
	if segments_to_decay.size() > 0 and Players.is_round_ongoing:
		var rand = rng.randi_range(0, segments_to_decay.size() - 1)
		var chosen_segment_index = segments_to_decay[rand]
		for segment in get_children():
			if segment.initial_segment_index == chosen_segment_index:
				segment.destroy()
				crust_decay.start()
				segments_to_decay.erase(chosen_segment_index)
		
