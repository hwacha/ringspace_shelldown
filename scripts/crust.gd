extends Node2D

export(int) var num_segments = 80
export(int) var crust_ratio = 1.0 / 15.0 # 1 is the length of the screen

var screen_size
var outer_radius
var inner_radius
var midpoint_radius
var crust_size

func _ready():
	screen_size = get_viewport().size
	transform.origin.x = screen_size.x / 2
	transform.origin.y = screen_size.y / 2
	outer_radius = min(screen_size.x, screen_size.y) / 2
	crust_size = outer_radius * crust_ratio
	inner_radius = outer_radius - crust_size
	
	var d_theta = 2 * PI / num_segments
	midpoint_radius = (outer_radius + inner_radius) / 2
	print(midpoint_radius)
	
	for i in range(num_segments):
		var collider = CollisionShape2D.new()
		var cord = RectangleShape2D.new()
		cord.extents = Vector2(PI * midpoint_radius / num_segments, crust_size / 2)
		collider.shape = cord
		
		var theta = i * d_theta
		
		collider.rotation = theta + (PI / 2)
		collider.transform.origin = midpoint_radius * Vector2(cos(theta), sin(theta))
		
		self.add_child(collider)
		
	get_node("/root/Players").spawn_players()
	
func _draw():
	draw_arc(Vector2(0, 0), \
	midpoint_radius, 0, 2 * PI, num_segments, Color(0.125, 0.125, 0.125, 1), crust_size, true)

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
