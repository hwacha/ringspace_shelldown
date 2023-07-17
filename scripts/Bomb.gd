extends AnimatableBody2D

var player_who_dropped : Player
var player_who_dropped_id : int
var velocity : Vector2

var cf = 0.105

enum BombStatus {
	TICKING,
	BLASTING,
	STUNNING
}

@export var status : BombStatus = BombStatus.TICKING
var has_destroyed_one_crust_segment : bool = false

func set_player_who_dropped(player):
	player_who_dropped = player
	player_who_dropped_id = player.id

func _ready():
	rotation = self.transform.origin.angle_to_point(Vector2(540, 540)) + PI/2
	$AnimationPlayer.play("tickboom")
	

func _process(delta):
	if status == BombStatus.TICKING:
		velocity += (self.transform.origin - Vector2(540, 540)) * cf * delta
		move_and_collide(velocity)
	else:
		velocity = Vector2(0, 0)
		
	
	if $BlastRadius.monitoring:
		var affected_bodies = $BlastRadius.get_overlapping_bodies()
		if affected_bodies == null:
			return

		if status == BombStatus.BLASTING:
			if not has_destroyed_one_crust_segment:
				var blasted_crust = affected_bodies.filter(func (body): return body is CrustSegment)
				
				var closest_segment = null
				var closest_distance = INF

				for segment in blasted_crust:
					var cur_distance = (segment.transform.origin + Vector2(540, 540)).distance_squared_to(self.transform.origin)
					if closest_segment == null or cur_distance < closest_distance:
						closest_segment = segment
						closest_distance = cur_distance
				
				if closest_segment != null:
					closest_segment.destroy()
					has_destroyed_one_crust_segment = true
		
		var affected_players = affected_bodies.filter(func (body): return body is Player)
		for player in affected_players:
			if not player.dead:
				if status == BombStatus.BLASTING:
					player.killer = player_who_dropped
					player.killer_id = player_who_dropped_id
					player.die()
				elif status == BombStatus.STUNNING:
					player.stunned = true
		



func _on_animation_player_animation_finished(anim_name):
	if anim_name == "tickboom":
		get_parent().remove_child(self)
		self.queue_free()
