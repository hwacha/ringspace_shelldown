extends Path2D

var player

var t = 0

var base_scale

func _ready():
	base_scale = $PathFollow2D/Sprite2D.scale

func _process(delta):
	$Line2D.clear_points()
	for point in self.curve.get_baked_points().slice(0, int(min(1, t) * self.curve.get_baked_length())):
		$Line2D.add_point(point + self.position)
		

	var black_hole = get_node_or_null("/root/Main/BlackHole")
	if black_hole != null:
		curve.set_point_position(0, black_hole.position)

	if $PathFollow2D.progress_ratio >= 1 - 0.001:
		player.spawn(false)
		get_parent().remove_child(self)
		self.queue_free()

	$PathFollow2D.progress_ratio = t
	$PathFollow2D/Sprite2D.scale.x = base_scale.x * (2 - 2 * max(abs(0.5 - t), 0.01))
	$PathFollow2D/Sprite2D.scale.y = base_scale.y * t 
	t += delta
