extends Node2D

export(int) var num_segments = 80
export(int) var crust_size = 30

var screen_size
var midpoint_radius

func _ready():
	screen_size = get_viewport().size
	var outer_radius = min(screen_size.x, screen_size.y) / 2
	print(outer_radius)
	var inner_radius = outer_radius - crust_size
	print(inner_radius)
	
	var d_theta = 2 * PI / num_segments
	midpoint_radius = (outer_radius + inner_radius) / 2
	
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
