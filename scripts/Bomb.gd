extends RigidBody2D

var player_who_dropped : Player
var velocity : Vector2

var cf = 0.105

func _ready():
	rotation = self.transform.origin.angle_to_point(Vector2(540, 540)) + PI/2
	$AnimationPlayer.play("tick")
	

func _process(delta):
	velocity += (self.transform.origin - Vector2(540, 540)) * cf * delta
	move_and_collide(velocity)
	
	if $InnerBlastRadius.monitoring:
		var blasted_bodies = $InnerBlastRadius.get_overlapping_bodies()
		if blasted_bodies == null:
			return

		var blasted_crust = blasted_bodies.filter(func (body): return body is CrustSegment)
		var blasted_players = blasted_bodies.filter(func (body): return body is Player)
		
		var closest_segment = null
		var closest_distance = INF

		for segment in blasted_crust:
			print(segment)
			var cur_distance = segment.transform.origin.distance_squared_to(self.transform.origin)
			if closest_segment == null or cur_distance < closest_distance:
				closest_segment = segment
				closest_distance = cur_distance
		
		if closest_segment != null:
			closest_segment.get_parent().remove_child(closest_segment)
			closest_segment.queue_free()
			
			$InnerBlastRadius.monitoring = false
			get_parent().remove_child(self)
			self.queue_free()
			
		for player in blasted_players:
			pass # TODO kill players
		



func _on_animation_player_animation_finished(anim_name):
	if anim_name == "tick":
		$InnerBlastRadius.monitoring = true
