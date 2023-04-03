extends Node2D

export(int) var num_segments = 16
export(int) var colliders_per_segment = 5
export(int) var crust_ratio = 1.0 / 15.0 # 1 is the length of the screen

var screen_size
var outer_radius
var inner_radius
var midpoint_radius
var crust_size

var rng
onready var crust_decay = get_node("../CrustDecay")

func _ready():
	screen_size = get_viewport().size
	transform.origin.x = screen_size.x / 2
	transform.origin.y = screen_size.y / 2
	outer_radius = min(screen_size.x, screen_size.y) / 2
	crust_size = outer_radius * crust_ratio
	inner_radius = outer_radius - crust_size
	
	midpoint_radius = (outer_radius + inner_radius) / 2
	
	var segment_d_theta = 2 * PI / num_segments
	
	var num_colliders = num_segments * colliders_per_segment
	var collider_d_theta = segment_d_theta / colliders_per_segment
	
	var crust_segment_scene = load("res://scenes/CrustSegment.tscn")
	
	for i in range(num_segments):
		var crust_segment = crust_segment_scene.instance()
		crust_segment.set_name("segment_" + str(i))
		crust_segment.midpoint_radius = midpoint_radius
		crust_segment.crust_size = crust_size
		crust_segment.num_segments = num_segments
		crust_segment.colliders_per_segment = colliders_per_segment
		crust_segment.arc_index = i
		var crust_segment_theta = i * segment_d_theta
		
		for j in range(colliders_per_segment):
			var cord = RectangleShape2D.new()
			cord.extents = Vector2(PI * midpoint_radius / num_colliders, crust_size / 2)
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
	crust_decay.start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass

func _on_CrustDecay_timeout():
	var rand = rng.randi_range(0, get_child_count() - 1)
	remove_child(get_child(rand))
	crust_decay.set_wait_time(crust_decay.wait_time * 0.5)
	crust_decay.start()
