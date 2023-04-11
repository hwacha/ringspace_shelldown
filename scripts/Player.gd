extends KinematicBody2D

export(int) var id

var perp_velocity = Vector2(0, 0)
var velocity = Vector2(0, 0)
var cf = 0.105

var perp_speed = 40 * 0.75
var jump_impulse = 2.6

var starting_theta
var centroid
var surface_to_centroid
var surface_to_centroid_squared

onready var anim = $AnimatedSprite

var fast_falling = false
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
	
func get_input(diff):
	perp_velocity = Vector2(0, 0)
	var ps = perp_speed
	var grounded = self.is_on_floor()
	if grounded:
		ps *= 15
		fast_falling = false
		
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
	
	var jump_animation_ongoing = anim.animation == "jumping" and anim.get_frame() < 2

	if cw_xor_ccw:
		if move_clockwise:
			perp_velocity += diff.rotated(PI / 2).normalized() * ps
			anim.flip_h = true
		if move_counterclockwise:
			perp_velocity += diff.rotated(-PI / 2).normalized() * ps
			anim.flip_h = false
		if grounded:
			anim.set_animation("running")
		elif not jump_animation_ongoing:
				anim.set_animation("falling")
	else:
		if grounded:
			anim.set_animation("default")
		elif not jump_animation_ongoing:
				anim.set_animation("falling")
		
	if jump and grounded:
		velocity += -diff * jump_impulse
		anim.set_animation("jumping")
		$Jump.play()
	
	if not grounded and fast_fall:
		fast_falling = true

func _physics_process(delta):
	if dead:
		return

	var diff = self.transform.origin - centroid
	self.rotation = self.transform.origin.angle_to_point(centroid) - (PI / 2)

	var fast_fall_mult = 1
	
	if fast_falling and Players.settings.fast_fall_enabled:
		fast_fall_mult = 10
		
	velocity += diff * cf * fast_fall_mult
	
	get_input(diff)
	
	var new_velocity = move_and_slide(velocity + perp_velocity, -diff)
	velocity = new_velocity.normalized() * velocity.length()
#	velocity -= perp_velocity
	
	if is_on_floor():
		velocity = Vector2(0, 0)

func _on_HurtBox_area_entered(hitbox):
	var hitter = hitbox.get_parent()
	if self.dead or hitter.dead:
		return
	# if the hitbox is moving down or
	# the hurtbox is moving up, DEATH
	var hitbox_down  = hitter.transform.origin - centroid
	var hurtbox_down = self.transform.origin - centroid
	
	if hitter.velocity.dot(hitbox_down) > 0 or \
	   velocity.dot(hurtbox_down) < 0:
		# bounce
		hitter.velocity = -hurtbox_down * jump_impulse * (surface_to_centroid / hurtbox_down.length())
		hitter.fast_falling = false
		# kill
		self.die()

func die():
	dead = true
	Players.player_killed(self.id)
	velocity = Vector2(0, 0)
	$AnimatedSprite.hide()
	$CollisionShape2D.set_deferred("disabled", true)
	$HitBox.set_deferred("monitoring", false)
	$HurtBox.set_deferred("monitorable", false)
	# death animation
	$DeathParticles.show()
	$DeathParticles.emitting = true
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
		
