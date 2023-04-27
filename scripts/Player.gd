class_name Player
extends CharacterBody2D

@export var id: int

var norm_velocity = Vector2(0, 0)
var perp_velocity = Vector2(0, 0)
#var velocity = Vector2(0, 0)
var cf = 0.105

var perp_speed = 40 * 0.75
var jump_impulse = 2.6

var starting_theta
var centroid : Vector2
var surface_to_centroid
var surface_to_centroid_squared

@onready var anim = $AnimatedSprite2D
var rand = RandomNumberGenerator.new()

var fast_falling = false: set = set_fast_falling
var dead = false
var first_spawn = true
var lock_physics = false
var jump_complete = false # true on the last frame of the jump animation
var invulnerable = false

var ontop_of = []

func _ready():
	
	var crust = get_node("../Crust")
	centroid = crust.transform.origin
	surface_to_centroid = min(crust.screen_size.x, crust.screen_size.y) / 2 - crust.crust_size
	surface_to_centroid_squared = surface_to_centroid * surface_to_centroid
	
	if first_spawn:
		transform.origin = centroid + \
		(Vector2(cos(starting_theta) * crust.screen_size.x / 10, \
			sin(starting_theta) * crust.screen_size.y / 10))
	else:
		spawn()
	
	rand.randomize()
	
	anim.set_animation("default")
	anim.play()

func spawn():
	# randomly select a safe crust segment
	var crust_segments = get_parent().get_node("Crust").get_children()
	var crust_index = rand.randi_range(0, crust_segments.size() - 1)
	var destination_segment = crust_segments[crust_index]
	if destination_segment.get_node("AnimationPlayer").current_animation == "segment_destroy":
		var second_crust_index = rand.randi_range(0, crust_segments.size() - 2)
		if second_crust_index >= crust_index:
			second_crust_index += 1
		destination_segment = crust_segments[second_crust_index]
	
	# invulnerable
	invulnerable = true
	$TeleportInvulnerability.start()
	
	# teleport
	norm_velocity = Vector2(0, 0)
	perp_velocity = Vector2(0, 0)
	transform.origin = (get_parent().get_node("Crust").transform.origin + 0.7 * \
	destination_segment.get_node("Visuals").transform.origin)

func get_input(diff):
	perp_velocity = Vector2(0, 0)
	var ps = perp_speed
	var grounded = self.is_on_floor()

	if grounded:
		ps *= 15
		set_fast_falling(false)
		
	var move_clockwise = Input.is_action_pressed("move_clockwise_p" + str(id))
	var move_counterclockwise = Input.is_action_pressed("move_counterclockwise_p" + str(id))
	
	var jump_input = Input.is_action_just_pressed("jump_p" + str(id))
	var fast_fall = Input.is_action_just_pressed("fast_fall_p" + str(id))
	var teleport = Input.is_action_just_pressed("teleport_p" + str(id))
	
	var cw_xor_ccw = move_clockwise or move_counterclockwise
	cw_xor_ccw = cw_xor_ccw and not (move_clockwise and move_counterclockwise)
	
	jump_input = jump_input and not Players.lock_action
	fast_fall = fast_fall and not Players.lock_action
	cw_xor_ccw = cw_xor_ccw and not Players.lock_action
	teleport = teleport and not Players.lock_action
	
	var jump_animation_ongoing = anim.animation == "jumping"

	if cw_xor_ccw:
		if move_clockwise:
			perp_velocity += diff.rotated(PI / 2).normalized() * ps
			anim.flip_h = true
		if move_counterclockwise:
			perp_velocity += diff.rotated(-PI / 2).normalized() * ps
			anim.flip_h = false
		if not jump_animation_ongoing:
			if grounded:
				anim.set_animation("running")
			elif fast_falling:
				anim.set_animation("fastfalling")
			else:
				anim.set_animation("falling")
	else:
		if not jump_animation_ongoing:
			if grounded:
				anim.set_animation("default")
			elif fast_falling:
				anim.set_animation("fastfalling")
			else:
				anim.set_animation("falling")
		
	if grounded and not jump_animation_ongoing:
		if jump_input:
			anim.set_animation("jumping")
			$Jump.play()
	
	if grounded and jump_complete:
			norm_velocity += -diff * jump_impulse
			jump_complete = false
	
	if not grounded and fast_fall:
		set_fast_falling(true)
	

func _physics_process(_delta):
	if lock_physics:
		return

	var diff = self.transform.origin - centroid
	
	self.rotation = self.transform.origin.angle_to_point(centroid) + (PI / 2)

	var fast_fall_mult = 1
	
	if fast_falling:
		fast_fall_mult = 10

#	var old_norm_velocity = norm_velocity
	norm_velocity += diff * cf * fast_fall_mult
#	if not self.is_on_floor() and id == 1:
#		print(norm_velocity.length() - old_norm_velocity.length())
	
	if not dead:
		get_input(diff)
	
	set_velocity(norm_velocity + perp_velocity)
	set_up_direction(-diff)
	move_and_slide()
	norm_velocity = velocity.normalized() * norm_velocity.length()
#	velocity -= perp_velocity
	
	if is_on_floor():
		norm_velocity = Vector2(0, 0)

func set_fast_falling(new_fast_falling):
	if not fast_falling and new_fast_falling:
		$FastFall.play()
		anim.set_animation("fastfalling")
	elif fast_falling and not new_fast_falling:
		$FastFall.stop()
	
	fast_falling = new_fast_falling
		
func _on_HurtBox_area_entered(hitbox):
	var hitter = hitbox.get_parent()
	if self.dead or hitter.dead or self.invulnerable or hitter.invulnerable:
		return
	# if the hitbox is moving down or
	# the hurtbox is moving up, DEATH
	var hitbox_down  = hitter.transform.origin - centroid
	var hurtbox_down = self.transform.origin - centroid
	
	if hitter.norm_velocity.dot(hitbox_down) > 0 or \
	norm_velocity.dot(hurtbox_down) < 0:
		# bounce
		hitter.norm_velocity = -hurtbox_down * jump_impulse * (surface_to_centroid / hurtbox_down.length())
		hitter.set_fast_falling(false)
		# kill
		self.die()

func die():
	if dead:
		return

	dead = true
	norm_velocity = Vector2(0, 0)
	$AnimatedSprite2D.set_animation("dead")
	$HitBox.set_deferred("monitoring", false)
	$HurtBox.set_deferred("monitorable", false)
	# death animation
	$DeathParticles.show()
	$DeathParticles.emitting = true
	$Death.play()
	$DeathTimer.start()
	# spawn orb
	var orb_scene = load("res://scenes/Orb.tscn")
	var orb_instance = orb_scene.instantiate()
	orb_instance.id = self.id
	orb_instance.centroid = self.centroid
	orb_instance.modulate = $DeathParticles.modulate
	orb_instance.get_node("PointLight2D").color = orb_instance.modulate
	orb_instance.transform.origin = self.transform.origin
	
	get_parent().call_deferred("add_child", orb_instance)
	for orb in $Orbs.get_children():
		orb.claimed = false
		$Orbs.remove_child(orb)
		orb.transform.origin = self.transform.origin
		get_parent().call_deferred("add_child", orb)
		

func _on_DeathTimer_timeout():
	Players.respawn_player(self.id, self.get_process_priority())
	hide()
	queue_free()
	
func on_respawn():
	spawn()

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
		anim.set_animation("falling")
		anim.play()


func _on_teleport_invulnerability_timeout():
	invulnerable = false
