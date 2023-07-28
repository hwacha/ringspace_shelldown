extends Path2D

class_name BlackHoleExit

var player

var t = 0

var base_scale

var player_id : int
var destination_segment : CrustSegment

func _ready():
	base_scale = $PathFollow2D/Sprite2D.scale

func _process(delta):
	if player == null or player.dead:
		if player_id in destination_segment.occupying_players:
			destination_segment.occupying_players.erase(player_id)
		
		get_parent().remove_child(self)
		self.queue_free()
		return
		
	$Line2D.clear_points()
	for point in self.curve.get_baked_points().slice(0, int(min(1, t) * self.curve.get_baked_length())):
		$Line2D.add_point(point + self.position)
		

	var black_hole = get_node_or_null("/root/Main/BlackHole")
	if black_hole != null:
		curve.set_point_position(0, black_hole.position)

	if $PathFollow2D.progress_ratio >= 1 - 0.01:
		if player_id in destination_segment.occupying_players:
			destination_segment.occupying_players.erase(player_id)
		player.spawn(false)

		get_parent().remove_child(self)
		self.queue_free()

	$PathFollow2D.progress_ratio = t
	$PathFollow2D/Sprite2D.scale.x = base_scale.x * (2 - 2 * max(abs(0.5 - t), 0.01))
	$PathFollow2D/Sprite2D.scale.y = base_scale.y * t 
	t += delta
