class_name Player
extends CharacterBody2D

signal used_powerup(reference)

@export var id: int
var color : Color

var double_jump_animation = preload("res://scenes/double_jump_animation.tscn")

var coyote_threshold : int = 5
var frames_in_air : int = 0
var was_grounded_last_frame : bool = false
var frames_stuck : int = 0

var norm_velocity = Vector2(0, 0)
var perp_velocity = Vector2(0, 0)

var analog_dead_zone = 0.05
#var velocity = Vector2(0, 0)
var cf = 0.105

var perp_speed = 40 * 0.75
var jump_impulse = 2.6
var double_jump_impulse = 1.8

var expansion_factor = 2.0
var fast_increase_factor = 1.5

var starting_theta
var centroid : Vector2
var surface_to_centroid
var surface_to_centroid_squared
var spawn_ratio

var segment_spawn_index = -1

@onready var anim = $AnimatedSprite2D
var rand = RandomNumberGenerator.new()

var t = 0

var prepping_fastfall = false : set = set_prepping_fastfall
var fast_falling = false: set = set_fast_falling
var fastfall_depleted = false
var dead = false
var killer = null
var killer_id = -1
var first_spawn = true
var lock_physics = false
var jump_complete = false # true on the last frame of the jump animation
var invulnerable = false : set = _set_invulnerability
var spawning = 0 # 0 if not spawning, n if n frames till black hole available
var stunned = false : set = _set_stun
var expanded = false : set = _set_expansion
var speedy = false
var shields : Array[Timer] = []

var ontop_of = []
var black_hole = null
var is_in_event_horizon = false : set = _set_is_in_event_horizon
var event_horizon_entry_point = null
var time_in_event_horizon : float = 0 # seconds

var orb_sound_queue = 0 : set = set_orb_sound_queue

func _ready():
	var crust = get_node("../../Crust")
	centroid = crust.transform.origin
	surface_to_centroid = min(crust.screen_size.x, crust.screen_size.y) / 2 - crust.crust_size
	surface_to_centroid_squared = surface_to_centroid * surface_to_centroid
	if first_spawn:
		transform.origin = centroid + \
		(Vector2(cos(starting_theta) * crust.screen_size.x / 10, \
			sin(starting_theta) * crust.screen_size.y / 10))
	else:
		spawn(false)
	
	rand.randomize()
	
	$ShadowSprite.modulate = color
	$TrailingPowerup.position = $TrailRightDestination.global_transform.origin if $AnimatedSprite2D.flip_h else $TrailLeftDestination.global_transform.origin
	
	var powerup = get_node("../../Powerups/Powerup" + str(id))
	used_powerup.connect(powerup.on_use_powerup)
	
	anim.set_animation("default")
	anim.play()

func _set_invulnerability(is_invulnerable: bool):
	invulnerable = is_invulnerable
	$AnimatedSprite2D.material.set("shader_parameter/is_invulnerable", is_invulnerable)

func _set_stun(is_stunned: bool):
	if is_stunned:
		$StunTimer.start()
	elif not $StunTimer.is_stopped():
		$StunTimer.stop()
	
	$Stun.visible = is_stunned
	stunned = is_stunned

func add_shields(num_shields: int):
	for i in range(num_shields):
		var shield_timer = Timer.new()
		shield_timer.wait_time = 5
		shield_timer.timeout.connect(_on_shield_timer_timeout)
		get_parent().get_parent().add_child(shield_timer)
		shield_timer.start()
		shields.push_back(shield_timer)
	
	if shields.size() >= 1 and not $Shield1.playing:
		$Shield1.play()
		$Shield2.play()
	
	$Shield2.volume_db = $Shield1.volume_db + 3 if shields.size() >= 2 else -80
	$AnimatedSprite2D.material.set("shader_parameter/num_shields", shields.size())

func remove_shields(num_shields: int) -> bool:
	var excess_shield_break = false
	for i in range(num_shields):
		var cur_timer = shields.pop_front()
		if cur_timer == null:
			excess_shield_break = true
			break
		else:
			cur_timer.stop()
			get_parent().get_parent().remove_child(cur_timer)
			cur_timer.queue_free()

	$AnimatedSprite2D.material.set("shader_parameter/num_shields", shields.size())
	
	if shields.size() == 0:
		$Shield1.stop()
		$Shield2.stop()
	
	$Shield2.volume_db = $Shield1.volume_db + 3 if shields.size() >= 2 else -80
	
	return excess_shield_break
	
func _set_expansion(new_expanded: bool):
	if not expanded and new_expanded:
		scale *= expansion_factor
		$Expand.play()
	elif expanded and not new_expanded:
		scale /= expansion_factor
		if not dead:
			$Deflate.play()
		if not $ExpandTimer.is_stopped():
			$ExpandTimer.stop()
		
	expanded = new_expanded


func find_crust_segment_to_spawn() -> CrustSegment:
	var crust_index = segment_spawn_index
	var crust_segments = get_node("../../Crust").get_children()
	if crust_index == -1:
		crust_segments = crust_segments.filter(func(segment): return segment.can_spawn_player())
		# randomly select a safe crust segment
		crust_index = rand.randi_range(0, crust_segments.size() - 1)
	return crust_segments[crust_index]

func spawn(is_teleport: bool):
	spawning = 2
	
	var destination_segment = find_crust_segment_to_spawn()
	destination_segment.occupying_players.push_back(self.id)
	var destination_segment_position = destination_segment.transform.origin
		
	var destination_point = (get_node("../../Crust").transform.origin +
		(1 - (48 / destination_segment_position.length())) * destination_segment_position)
	
	# invulnerable
	invulnerable = true
	$TeleportInvulnerability.start()
	
	# teleport
	norm_velocity = Vector2(0, 0)
	perp_velocity = Vector2(0, 0)
	
	if is_teleport:
		self.visible = false
		self.lock_physics = true
		var teleport_animation = preload("res://scenes/TeleportAnimation.tscn").instantiate()
		teleport_animation.player = self
		teleport_animation.source = self.transform.origin
		self.transform.origin = Vector2(-100000, -100000)
		teleport_animation.destination = destination_point
		
		get_parent().add_child(teleport_animation)
	else:
		transform.origin = destination_point
	
	stunned = false
	segment_spawn_index = -1
	
	return true

func try_auto_teleport():
	var my_powerup = get_node("../../Powerups/Powerup" + str(self.id))
	if my_powerup.powerup == "teleport":
		emit_signal("used_powerup", self)
		return true
	return false
	
func expand():
	if not expanded:
		expanded = true
		$ExpandTimer.start()
		return true
	return false

func fast():
	if not speedy:
		speedy = true
		$FastTimer.start()
		return true
	return false

func shield():
	if shields.size() < 2:
		add_shields(1)
		return true
	return false
	
func comet():
	var comet_instance = preload("res://scenes/Comet.tscn").instantiate()
	comet_instance.player_who_shot = self
	var dir_sign = -1
	if anim.flip_h:
		dir_sign *= -1
	comet_instance.dir_sign = dir_sign
	comet_instance.centroid = self.centroid
	var diff = self.transform.origin - centroid
	var perp = diff.rotated(dir_sign * PI / 2).normalized()
	
	comet_instance.rotation = diff.angle()
	comet_instance.transform.origin = self.transform.origin + 40 * perp
	
	get_parent().get_parent().add_child(comet_instance)
	
	return true
	
func vacuum():
	var vacuum_instance = preload("res://scenes/OrbVacuum.tscn").instantiate()
	vacuum_instance.player_who_threw = self
	vacuum_instance.modulate = color
	
	var analog_h_movement = Input.get_axis("move_left_analog_p" + str(id), "move_right_analog_p" + str(id))
	var analog_v_movement = Input.get_axis("move_up_analog_p" + str(id), "move_down_analog_p" + str(id))
	var analog_movement = Vector2(analog_h_movement, analog_v_movement)
	
	if analog_movement.is_zero_approx():
		if is_on_floor():
			vacuum_instance.velocity = self.position.direction_to(centroid) * 720
		else:
			vacuum_instance.velocity = (norm_velocity + perp_velocity).normalized() * 720
	else:
		vacuum_instance.velocity = analog_movement * 720

	vacuum_instance.transform.origin = self.transform.origin
	get_parent().get_parent().add_child(vacuum_instance)
	return true
	
func bomb():
	var bomb_instance = preload("res://scenes/Bomb.tscn").instantiate()
	bomb_instance.player_who_dropped = self
	
	var drop_speed = 3
	bomb_instance.velocity = drop_speed * -self.transform.origin.direction_to(centroid)
	
	bomb_instance.transform.origin = self.transform.origin
	
	get_parent().get_parent().add_child(bomb_instance)
	return true

func set_orb_sound_queue(new_orb_sound_queue):
	if new_orb_sound_queue > 5:
		return

	if orb_sound_queue == 0 and new_orb_sound_queue > 0:
		if $OrbCollect/Timer.is_stopped():
			$OrbCollect.play()
			$OrbCollect/Timer.start()
			orb_sound_queue = new_orb_sound_queue - 1
	elif orb_sound_queue > 0 and new_orb_sound_queue == 0:
		$OrbCollect/Timer.stop()
	else:
		$OrbCollect.play()
	
	orb_sound_queue = new_orb_sound_queue

func get_input(diff):
	perp_velocity = Vector2(0, 0)
	var ps = perp_speed
	
	var grounded = self.is_on_floor()
	if grounded:
		ps *= 15
		if speedy:
			ps *= fast_increase_factor
		set_fast_falling(false)
		fastfall_depleted = false
		$BounceTimer.stop()
		if spawning > 0:
			spawning -= 1
	else:
		# uncomment this for logistic speed curve
		var inflection_point = surface_to_centroid / 2
		var steepness = 1.0 / 150
		var max_multiplier = 3.0
		ps *= max_multiplier * (1 + tanh(steepness * (diff.length() - inflection_point)))

#		# uncomment this for linear speed curve
#		var linear_multiplier = 6.5
#		ps *= linear_multiplier * (diff.length() / surface_to_centroid)

#		# uncomment this for angular speed that decreases slightly superlinearlly from a maximum at the origin to zero somewhere outside the ring
#		var dist_frac = diff.length() / surface_to_centroid
#		var x = (1 - dist_frac + 0.2)
#		ps *= 7 * dist_frac * 0.5 * (x + x*x)
		
	var analog_h_movement = Input.get_axis("move_left_analog_p" + str(id), "move_right_analog_p" + str(id))
	var analog_v_movement = Input.get_axis("move_up_analog_p" + str(id), "move_down_analog_p" + str(id))
	
	var total_movement = Vector2(analog_h_movement, analog_v_movement)

	var horizontal_sign = total_movement.dot(diff.rotated(PI / 2).normalized())
	var analog_move_clockwise = horizontal_sign > analog_dead_zone
	var analog_move_counterclockwise = horizontal_sign < -analog_dead_zone
	
	var move_clockwise = analog_move_clockwise or Input.is_action_pressed("move_clockwise_p" + str(id))
	var move_counterclockwise = analog_move_counterclockwise or Input.is_action_pressed("move_counterclockwise_p" + str(id))
	
	var jump_input = Input.is_action_just_pressed("jump_p" + str(id))
	var fast_fall = Input.is_action_just_pressed("fast_fall_p" + str(id))
	var use = Input.is_action_just_pressed("use_p" + str(id))
	
	var cw_xor_ccw = move_clockwise or move_counterclockwise
	cw_xor_ccw = cw_xor_ccw and not (move_clockwise and move_counterclockwise)
	
	jump_input = jump_input and not Players.lock_action and not spawning > 1 and not stunned
	fast_fall = fast_fall and not Players.lock_action and not spawning > 1 and not stunned
	cw_xor_ccw = cw_xor_ccw and not Players.lock_action and not spawning > 1 and not stunned
	use = use and not Players.lock_action and not stunned
	
	var jump_animation_ongoing = anim.animation == "jumping"

	if cw_xor_ccw:
		if move_clockwise:
			perp_velocity += diff.rotated(PI / 2).normalized() * ps
			anim.flip_h = true
			$FastfallAnimation.flip_h = false
			$LeftArrow.visible = true
		if move_counterclockwise:
			perp_velocity += diff.rotated(-PI / 2).normalized() * ps
			anim.flip_h = false
			$FastfallAnimation.flip_h = true
			$RightArrow.visible = true
		if not jump_animation_ongoing:
			if grounded:
				anim.set_animation("running")
			elif not fast_falling:
				anim.set_animation("falling")
	else:
		if not jump_animation_ongoing:
			if grounded:
				anim.set_animation("default")
			elif not fast_falling:
				anim.set_animation("falling")
		
	if (grounded or frames_in_air < coyote_threshold) and not jump_animation_ongoing:
		if jump_input:
			anim.set_animation("jumping")
			$Jump.play()
	
	if jump_complete:
		var total_impulse = jump_impulse
		if speedy:
			total_impulse *= fast_increase_factor * 0.8
		norm_velocity += -diff * total_impulse
		jump_complete = false
		spawning = 0
		
	if jump_input and diff.dot(norm_velocity) > 0 and \
		not (jump_animation_ongoing or \
			grounded or \
			frames_in_air < coyote_threshold or \
			fastfall_depleted):
		var normalized_diff = diff.normalized()
		norm_velocity += -normalized_diff * norm_velocity.dot(normalized_diff)
		norm_velocity += -normalized_diff * max(diff.length(), 200) * double_jump_impulse
		fastfall_depleted = true
		set_fast_falling(false)
		
		var double_jump_animation_instance = double_jump_animation.instantiate()
		get_parent().get_parent().add_child(double_jump_animation_instance)
		double_jump_animation_instance.scale = scale * Vector2(0.1, 0.1)
		double_jump_animation_instance.rotation = self.rotation
		double_jump_animation_instance.transform.origin = self.transform.origin -\
			30 * Vector2(cos(self.rotation + PI/2), sin(self.rotation + PI/2))
		
		double_jump_animation_instance.play()
		
	if fast_fall and not (fast_falling or fastfall_depleted):
		if grounded and not jump_animation_ongoing or jump_input:
			prepping_fastfall = true
		else:
			set_fast_falling(true)
			
	if use:
		emit_signal("used_powerup", self)
		
func whiff_powerup():
	var src = $TrailRightDestination if $AnimatedSprite2D.flip_h else $TrailLeftDestination
	$PowerupWhiff.position = src.position
	$PowerupWhiff.restart()
	$PowerupWhiff.emitting = true

func _physics_process(delta):
	if lock_physics:
		return
	
	if spawning < 2:
		var stuck_in_crust = move_and_collide(Vector2(0, 0), true)
		if stuck_in_crust != null:
			frames_stuck += 1
		else:
			frames_stuck = 0
	else:
		frames_stuck += 1
		
	if frames_stuck > 3:
		frames_stuck = 0
		spawn(false)
		return

	t += delta
	var powerup = get_node("/root/Main/Powerups/Powerup" + str(self.id))
	var powerup_sprite = powerup.get_node("Sprite2D")
	$TrailingPowerup.texture = powerup_sprite.texture
	$TrailingPowerup.offset = 40 * Vector2(0, sin(t * 5))
	
	var destination = $TrailRightDestination if $AnimatedSprite2D.flip_h else $TrailLeftDestination
	
	$TrailingPowerup.position = $TrailingPowerup.position.lerp(destination.global_transform.origin, delta * 8.0)
	$TrailingPowerup.rotation = $TrailingPowerup.position.angle_to_point(Vector2(540,540)) + PI/2
	$TrailingPowerup.scale = 0.05 * powerup.scale * ((expansion_factor * 0.75) if expanded else 1.0)
	$TrailingPowerup.modulate = powerup.modulate * powerup_sprite.modulate
	
	$LeftArrow.visible = false
	$RightArrow.visible = false
	
	$ShadowSprite.visible = true
	
	if stunned:
		var rand_theta = rand.randf_range(0, 2 * PI)
		$AnimatedSprite2D.offset = 20 * Vector2(cos(rand_theta), sin(rand_theta))
	else:
		$AnimatedSprite2D.offset = Vector2(0, 0)

	if is_on_floor():
		frames_in_air = 0
		prepping_fastfall = false
		$ShadowSprite.visible = false
		
		# big stuns nearby players
		if not was_grounded_last_frame and expanded and fast_falling:
			for player in get_parent().get_children():
				if player == self:
					continue
				
				# don't restun
				if player.stunned:
					continue
				
				var stun_threshold = 200
				var st2 = stun_threshold * stun_threshold
				if player.transform.origin.distance_squared_to(self.transform.origin) <= st2:
					player.stunned = true
		
		was_grounded_last_frame = true
	else:
		frames_in_air += 1
		was_grounded_last_frame = false
		
		if is_in_event_horizon:
			$ShadowSprite.visible = false
		else:
			var shadow_target  = $Shadow.get_collider()
			var shadow_target_right = $ShadowRight.get_collider()
			var shadow_target_left = $ShadowLeft.get_collider()
			if shadow_target == null and shadow_target_left == null and shadow_target_right == null:
				$ShadowSprite.visible = false
			else:
				var center_pos = $Shadow.get_collision_point()
				var right_pos = $ShadowRight.get_collision_point()
				var left_pos = $ShadowLeft.get_collision_point()
				
				var center_distance = (self.transform.origin + $Shadow.transform.origin).distance_to(center_pos)
				var right_distance = (self.transform.origin + $ShadowRight.transform.origin).distance_to(right_pos)
				var left_distance = (self.transform.origin + $ShadowLeft.transform.origin).distance_to(left_pos)
				
				if right_distance + 30 < center_distance and right_distance < left_distance:
					$ShadowSprite.transform.origin = right_pos
					$ShadowSprite.scale.x = lerpf(0.02, 0.1, clampf(1 - right_distance / 540, 0, 1))
				elif left_distance + 30 < center_distance and left_distance < right_distance:
					$ShadowSprite.transform.origin = left_pos
					$ShadowSprite.scale.x = lerpf(0.02, 0.1, clampf(1 - left_distance / 540, 0, 1))
				else:
					$ShadowSprite.transform.origin = center_pos
					$ShadowSprite.scale.x = lerpf(0.02, 0.1, clampf(1 - center_distance / 540, 0, 1))
		
				if expanded:
					$ShadowSprite.scale.x *= expansion_factor

				$ShadowSprite.rotation = self.rotation
				$ShadowSprite.visible = true

	var diff = self.transform.origin - centroid
	
	self.rotation = self.transform.origin.angle_to_point(centroid) + (PI / 2)

	var fast_fall_mult = 1
	
	if fast_falling:
		fast_fall_mult = 5

	norm_velocity += diff * cf * fast_fall_mult * Engine.time_scale
	
	if prepping_fastfall and frames_in_air > 20:
		prepping_fastfall = false
		fast_falling = true
	
	if not (dead or prepping_fastfall):
		get_input(diff)
	
	var total_velocity = norm_velocity + (perp_velocity * Engine.time_scale)
	
	if prepping_fastfall:
		total_velocity = Vector2(0, 0)
		if self.position.distance_squared_to(centroid) > (surface_to_centroid_squared * 9 / 25):
			self.position = lerp(self.position, centroid, 0.04)

	if black_hole != null and not (is_on_floor() or spawning):
		var black_hole_diff = black_hole.transform.origin - self.transform.origin
		var black_hole_direction = black_hole_diff.normalized()
		if is_in_event_horizon:
			prepping_fastfall = false
			$AnimatedSprite2D.animation = "falling"
			var period = 2.5 # seconds it takes to get to center
			self.transform.origin = black_hole.transform.origin + lerp(event_horizon_entry_point, Vector2(0, 0), time_in_event_horizon / period)
			total_velocity = Vector2(0, 0)
			self.rotation = self.transform.origin.angle_to_point(black_hole.transform.origin) - (PI / 2)
			time_in_event_horizon += delta
		else:
			var inverse_r2 = 1.0 / black_hole_diff.length_squared()
			total_velocity += black_hole_direction * 1_600_000.0 * inverse_r2
	
	set_velocity(total_velocity)
	set_up_direction((-diff).normalized())
	move_and_slide()
	norm_velocity = velocity.normalized() * norm_velocity.length()
	
	if is_on_floor():
		norm_velocity = Vector2(0, 0)
		
func _set_is_in_event_horizon(new_is_in_event_horizon):
	if not is_on_floor() and new_is_in_event_horizon:
		stunned = true
	if not $StunTimer.is_stopped():
		$StunTimer.stop()
	if new_is_in_event_horizon:
		fast_falling = false
		if event_horizon_entry_point == null:
			event_horizon_entry_point = transform.origin - black_hole.transform.origin
	else:
		event_horizon_entry_point = null
		time_in_event_horizon = 0
		stunned = false
	is_in_event_horizon = new_is_in_event_horizon

func set_prepping_fastfall(new_prepping_fastfall):
	if new_prepping_fastfall:
		$AnimatedSprite2D.animation = "default"
	prepping_fastfall = new_prepping_fastfall

func set_fast_falling(new_fast_falling):
	if not fast_falling and new_fast_falling:
		if not is_in_event_horizon:
			var diff = position - centroid
			if norm_velocity.dot(diff) < 0:
				norm_velocity = norm_velocity.project(diff.orthogonal())
			$FastFall.play()
			anim.set_animation("fastfalling")
			$FastfallAnimation.visible = true
			$FastfallAnimation.play()
	elif fast_falling and not new_fast_falling:
		$FastFall.stop()
		$FastfallAnimation.stop()
		$FastfallAnimation.visible = false
	fast_falling = new_fast_falling
		
func _on_HurtBox_area_entered(hitbox):
	var hitter = hitbox.get_parent()
	if self.dead or hitter.dead or self.invulnerable or hitter.invulnerable:
		return
	
	var epsilon = 20
	
	if self.transform.origin.distance_squared_to(hitter.transform.origin) < (epsilon * epsilon):
		return
	
	# if the hitbox is moving down or
	# the hurtbox is moving up, DEATH
	var hitbox_down  = hitter.transform.origin - centroid
	var hurtbox_down = self.transform.origin - centroid
	
	if (hitter.norm_velocity.dot(hitbox_down) > 0 or \
		self.norm_velocity.dot(hurtbox_down) < 0):
		# bounce
		hitter.norm_velocity = -hurtbox_down * jump_impulse
		hitter.set_fast_falling(false)
		hitter.fastfall_depleted = true
		hitter.get_node("BounceTimer").start()
		# kill
		if shields.size() > 0:
			var excess_hits = false
			var old_num_shields = shields.size()
			if hitter.expanded:
				excess_hits = remove_shields(3)
			else:
				excess_hits = remove_shields(1)
			
			var new_num_shields = shields.size()
			
			if old_num_shields >= 2 and new_num_shields < 2:
				$Shield2/Break.play()
			if old_num_shields >= 1 and new_num_shields < 1:
				$Shield1/Break.play()
			
			if not excess_hits:
				return
		
		self.killer = hitter
		self.killer_id = hitter.id
		self.die()
		

func die():
	if dead:
		return
	dead = true
	name += "_(dead)"
	stunned = false
	prepping_fastfall = false
	remove_shields(shields.size()) # not strictly necessary
	norm_velocity = Vector2(0, 0)
	$TrailingPowerup.visible = false
	$AnimatedSprite2D.set_animation("dead")
	$HitBox.set_deferred("monitoring", false)
	$HurtBox.set_deferred("monitorable", false)
	if $FastFall.playing:
		$FastFall.stop()
	$FastfallAnimation.visible = false
	# death animation
	$DeathParticles.show()
	$DeathParticles.emitting = true
	$Death.play()
	$DeathTimer.start()

func _on_DeathTimer_timeout():
	Players.respawn_player(self.id, self.get_process_priority())
	hide()
	queue_free()
	
func on_respawn():
	spawn(false)

func _on_Overlap_area_entered(area):
	var other = area.get_parent()
	if self.get_index() > other.get_index() and not other in ontop_of:
		ontop_of.push_back(other)
		self.modulate.a = 0.6

func _on_Overlap_area_exited(area):
	var other = area.get_parent()
	ontop_of.erase(other)
	if ontop_of == []:
		self.modulate.a = 1

func _on_animated_sprite_2d_frame_changed():
	if anim.animation == "jumping" and anim.frame == 2:
		jump_complete = true

func _on_teleport_invulnerability_timeout():
	invulnerable = false

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "jumping":
		anim.set_animation("falling")
		anim.play()
	elif anim.animation == "dead":
		# spawn orb
		var orb_scene = load("res://scenes/Orb.tscn")
		var orb_instance = orb_scene.instantiate()
		orb_instance.id = self.id
		orb_instance.centroid = self.centroid
		var orb_animated_sprite = orb_instance.get_node("AnimatedSprite2D")
		orb_animated_sprite.sprite_frames = \
			load("res://animations/SpriteFrames_Orb" + str(self.id) + ".tres")
		orb_animated_sprite.animation = "default"
		var orb_exit_location = self.transform.origin + \
			20 * (centroid - transform.origin).normalized()
		orb_instance.transform.origin = orb_exit_location
		
		var orb_loss_fraction = float(Players.orb_loss_numerator_hazard) / Players.orb_loss_denominator_hazard
		
		if killer != null or killer_id != -1:
			orb_loss_fraction = float(Players.orb_loss_numerator_kill) / Players.orb_loss_denominator_kill
			orb_instance.claimed = true
			orb_instance.next_claimant = killer
			orb_instance.next_claimant_id = killer_id
		
		get_parent().get_parent().call_deferred("add_child", orb_instance)

		var total_orbs = $Orbs.get_child_count()
		var num_lost_orbs = int(total_orbs * orb_loss_fraction)
		var counter = 0
		for orb in $Orbs.get_children():
			$Orbs.remove_child(orb)
			orb.transform.origin = self.transform.origin
			
			if counter < num_lost_orbs:
				get_parent().get_parent().call_deferred("add_child", orb)
				if killer == null:
					orb.claimed = false
				else:
					orb.claimed = true
					orb.next_claimant = killer
			else:
				Players.stored_orbs[self.id - 1].push_back(orb)
			
			counter += 1
			
		anim.set_animation("corpse")
		anim.play()

func _on_expand_timer_timeout():
	if expanded:
		expanded = false


func _on_fast_timer_timeout():
	if speedy:
		speedy = false

func _on_shield_timer_timeout():
	remove_shields(1)

func _on_bounce_timer_timeout():
	fastfall_depleted = false


func _on_stun_timer_timeout():
	stunned = false


func _on_orbcollect_timer_timeout():
	orb_sound_queue -= 1
