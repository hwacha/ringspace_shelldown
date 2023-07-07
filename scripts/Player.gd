class_name Player
extends CharacterBody2D

signal used_powerup(reference)

@export var id: int
var color : Color

var double_jump_animation = preload("res://scenes/double_jump_animation.tscn")

var coyote_threshold : int = 5
var frames_in_air : int = 0

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
var expanded = false : set = _set_expansion
var speedy = false
var shielded = 0 : set = _set_shieldedness

var ontop_of = []
var black_hole = null
var is_in_event_horizon = false : set = _set_is_in_event_horizon

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
	
	$ShadowSprite.modulate = $DeathParticles.modulate
	$ShadowSprite.modulate.a = 1
	
	var powerup = get_node("../../Powerups/Powerup" + str(id))
	used_powerup.connect(powerup.on_use_powerup)
	
	anim.set_animation("default")
	anim.play()

func _set_invulnerability(is_invulnerable: bool):
	invulnerable = is_invulnerable
	$AnimatedSprite2D.material.set("shader_parameter/is_invulnerable", is_invulnerable)

func _set_shieldedness(num_shields: int):
	shielded = num_shields
	$AnimatedSprite2D.material.set("shader_parameter/num_shields", num_shields)

func _set_expansion(new_expanded: bool):
	if not expanded and new_expanded:
		scale *= expansion_factor
	elif expanded and not new_expanded:
		scale /= expansion_factor
		
	expanded = new_expanded

func spawn(is_teleport: bool):
	spawning = 2
	# randomly select a safe crust segment
	var crust_index = segment_spawn_index
	var crust_segments = get_node("../../Crust").get_children().filter(func(segment): return segment.can_spawn_player())
	if crust_index == -1:
		crust_index = rand.randi_range(0, crust_segments.size() - 1)
	var destination_segment = crust_segments[crust_index]
	if destination_segment.get_node("AnimationPlayer").current_animation == "segment_destroy":
		var second_crust_index = rand.randi_range(0, crust_segments.size() - 2)
		if second_crust_index >= crust_index:
			second_crust_index += 1
		destination_segment = crust_segments[second_crust_index]
		
	destination_segment.occupying_players.push_back(self.id)
	
	var destination_segment_position = destination_segment.transform.origin
		
	var destination_point = (get_node("../../Crust").transform.origin +
		(1 - (48 / destination_segment_position.length())) * destination_segment_position)
	
	# invulnerable
	if segment_spawn_index == -1:
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
	if shielded < 2:
		shielded += 1
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
	
	get_parent().add_child(comet_instance)
	
	return true
	
func vacuum():
	var vacuum_instance = preload("res://scenes/OrbVacuum.tscn").instantiate()
	vacuum_instance.player_who_threw = self
	vacuum_instance.modulate = color
	
	var diff = self.transform.origin - centroid
	vacuum_instance.velocity = norm_velocity + perp_velocity
	if vacuum_instance.velocity.length() == 0:
		vacuum_instance.velocity = -diff
	vacuum_instance.transform.origin = self.transform.origin
	get_parent().add_child(vacuum_instance)
	return true

func get_input(diff):
	perp_velocity = Vector2(0, 0)
	var ps = perp_speed
	
	var grounded = self.is_on_floor()
	if grounded:
		ps *= 15
		if speedy:
			ps *= fast_increase_factor
		set_fast_falling(false)
		frames_in_air = 0
		fastfall_depleted = false
		$BounceTimer.stop()
		if spawning > 0:
			spawning -= 1
	else:
		# frame timer
		frames_in_air += 1
		
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
	
	jump_input = jump_input and not Players.lock_action
	fast_fall = fast_fall and not Players.lock_action
	cw_xor_ccw = cw_xor_ccw and not Players.lock_action
	use = use and not Players.lock_action
	
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

	if fast_fall and not (grounded or fast_falling or fastfall_depleted):
		set_fast_falling(true)
			
	if use:
		emit_signal("used_powerup", self)

func _physics_process(delta):
	$LeftArrow.visible = false
	$RightArrow.visible = false
	
	$ShadowSprite.visible = true
	
	if is_on_floor():
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
	
			$ShadowSprite.rotation = self.rotation
			$ShadowSprite.visible = true

	if lock_physics:
		return

	var diff = self.transform.origin - centroid
	
	self.rotation = self.transform.origin.angle_to_point(centroid) + (PI / 2)

	var fast_fall_mult = 1
	
	if fast_falling:
		fast_fall_mult = 5

	norm_velocity += diff * cf * fast_fall_mult * Engine.time_scale
	
	if not dead:
		get_input(diff)
	
	var total_velocity = norm_velocity + (perp_velocity * Engine.time_scale)
	
	if black_hole != null and not (is_on_floor() or spawning):
		var black_hole_diff = black_hole.transform.origin - self.transform.origin
		var black_hole_direction = black_hole_diff.normalized()
		if is_in_event_horizon:
			self.transform.origin += black_hole.difference_from_last_position
			self.transform.origin += transform.origin.direction_to(black_hole.transform.origin) * delta * 30
			total_velocity = Vector2(0, 0)
			self.rotation = self.transform.origin.angle_to_point(black_hole.transform.origin) - (PI / 2)
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
	if new_is_in_event_horizon:
		fast_falling = false
	is_in_event_horizon = new_is_in_event_horizon

func set_fast_falling(new_fast_falling):
	if not fast_falling and new_fast_falling:
		if not is_in_event_horizon:
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
	
	if hitter.norm_velocity.dot(hitbox_down) > 0 or \
	norm_velocity.dot(hurtbox_down) < 0:
		if not shielded and try_auto_teleport():
			return
		
		# bounce
		hitter.norm_velocity = -hurtbox_down * jump_impulse
		hitter.set_fast_falling(false)
		hitter.fastfall_depleted = true
		hitter.get_node("BounceTimer").start()
		# kill
		if shielded > 0:
			if hitter.expanded:
				shielded -= 3
			else:
				shielded -= 1
			if shielded >= 0:
				return
		
		self.killer = hitter
		self.killer_id = hitter.id
		self.die()
		

func die():
	if dead:
		return
	dead = true
	name += "_(dead)"
	shielded = 0 # not strictly necessary
	norm_velocity = Vector2(0, 0)
	$AnimatedSprite2D.set_animation("dead")
	$HitBox.set_deferred("monitoring", false)
	$HurtBox.set_deferred("monitorable", false)
	if $FastFall.playing:
		$FastFall.stop()
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
		
		if killer != null:
			orb_instance.claimed = true
			orb_instance.next_claimant = killer
		
		get_parent().get_parent().call_deferred("add_child", orb_instance)

		var total_orbs = $Orbs.get_child_count()
		var num_lost_orbs = int(total_orbs * \
		float(Players.orb_loss_numerator) / Players.orb_loss_denominator)
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


func _on_bounce_timer_timeout():
	fastfall_depleted = false
