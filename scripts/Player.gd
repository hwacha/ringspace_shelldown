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
var centroid
var surface_to_centroid
var surface_to_centroid_squared

@onready var anim = $AnimatedSprite2D
var jump_animation_ongoing = false

var fast_falling = false: set = set_fast_falling
var dead = false

var ontop_of = []

func _ready():
	var crust = get_node("../Crust")
	centroid = crust.transform.origin
	surface_to_centroid = min(crust.screen_size.x, crust.screen_size.y) / 2 - crust.crust_size
	surface_to_centroid_squared = surface_to_centroid * surface_to_centroid
	
	transform.origin = centroid + \
	(Vector2(cos(starting_theta) * crust.screen_size.x / 10, \
		sin(starting_theta) * crust.screen_size.y / 10))
	
	anim.play()
	
func get_input(diff):
	perp_velocity = Vector2(0, 0)
	var ps = perp_speed
	var grounded = self.is_on_floor()

	if grounded:
		ps *= 15
		set_fast_falling(false)
		
	var move_clockwise = Input.is_action_pressed("move_clockwise_p" + str(id))
	var move_counterclockwise = Input.is_action_pressed("move_counterclockwise_p" + str(id))
	
	if Players.settings.invert_controls:
		var temp = move_clockwise
		move_clockwise = move_counterclockwise
		move_counterclockwise = temp
		
	
	var jump = Input.is_action_just_pressed("jump_p" + str(id))
	var fast_fall = Input.is_action_just_pressed("fast_fall_p" + str(id))
	
	var cw_xor_ccw = move_clockwise or move_counterclockwise
	cw_xor_ccw = cw_xor_ccw and not (move_clockwise and move_counterclockwise)

	if cw_xor_ccw:
		if move_clockwise and not Players.lock_action:
			perp_velocity += diff.rotated(PI / 2).normalized() * ps
			anim.flip_h = true
		if move_counterclockwise and not Players.lock_action:
			perp_velocity += diff.rotated(-PI / 2).normalized() * ps
			anim.flip_h = false
		if grounded:
			if not Players.lock_action:
				anim.set_animation("running")
		elif not jump_animation_ongoing:
				anim.set_animation("falling")
	else:
		if grounded:
			anim.set_animation("default")
		elif not jump_animation_ongoing:
			anim.set_animation("falling")
		
	if jump and grounded and not Players.lock_action:
		norm_velocity += -diff * jump_impulse
		anim.set_animation("jumping")
		jump_animation_ongoing = false
		$Jump.play()
	
	if not grounded and fast_fall and not Players.lock_action:
		set_fast_falling(true)

func _physics_process(delta):
	if dead:
		return

	var diff = self.transform.origin - centroid
	
	self.rotation = self.transform.origin.angle_to_point(centroid) + (PI / 2)

	var fast_fall_mult = 1
	
	if fast_falling and Players.settings.fast_fall_enabled:
		fast_fall_mult = 10

#	var old_norm_velocity = norm_velocity
	norm_velocity += diff * cf * fast_fall_mult
#	if not self.is_on_floor() and id == 1:
#		print(norm_velocity.length() - old_norm_velocity.length())
		
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
	elif fast_falling and not new_fast_falling:
		$FastFall.stop()
	
	fast_falling = new_fast_falling
		
func _on_HurtBox_area_entered(hitbox):
	var hitter = hitbox.get_parent()
	if self.dead or hitter.dead:
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
	dead = true
	Players.player_killed(self.id)
	norm_velocity = Vector2(0, 0)
	$AnimatedSprite2D.hide()
	$CollisionShapeForGround.set_deferred("disabled", true)
	$HitBox.set_deferred("monitoring", false)
	$HurtBox.set_deferred("monitorable", false)
	# death animation
	$DeathParticles.show()
	$DeathParticles.emitting = true
	$Death.play()
	$DeathTimer.start()

func _on_DeathTimer_timeout():
	hide()
	queue_free()

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

func _on_animated_sprite_2d_animation_finished():
	if anim.animation == "jump":
		jump_animation_ongoing = false
