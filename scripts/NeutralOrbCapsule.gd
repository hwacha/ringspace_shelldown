extends Area2D

class_name NeutralOrbCapsule

var t : float = 0

@onready var original_position : Vector2
@onready var norm_direction : Vector2
var hover_amplitude : float = 4
var hover_speed : float = 2


# status
var is_opening : bool = false

func _ready():
	original_position = self.transform.origin
	var norm_theta = self.rotation - PI/2
	norm_direction = Vector2(cos(norm_theta), sin(norm_theta))
	
	# set orbs
	$Orbs.r = 15
	$Orbs.rotation_speed = 2.0
	for orb in $Orbs.get_children():
		orb.traveling = false
		orb.get_node("AnimatedSprite2D").sprite_frames = preload("res://animations/SpriteFrames_Orb5.tres")
		$Orbs.on_add_orb(orb)

func _process(_delta):
	self.transform.origin = original_position + hover_amplitude * sin(t * hover_speed) * norm_direction
	t += _delta
	
	if is_opening:
		$Orbs.transform.origin += 0.6 * Vector2(0, -1)


func _on_area_entered(area):
	var hitter = area.get_parent()
	var centroid = Vector2(540, 540)
	# check if player is above
	if hitter.transform.origin.distance_squared_to(centroid) >= self.transform.origin.distance_squared_to(centroid):
		return
	
	# check if player is moving downward
	var hurtbox_down = self.transform.origin - centroid
	
	if hitter.norm_velocity.dot(hitter.transform.origin - centroid) < 0:
		return
		
	# open the capsule
	$AnimatedSprite2D.animation = "open"
	
	# player is next orb claimant
	for orb in $Orbs.get_children():
		orb.next_claimant = hitter
	
	# bounce
	hitter.norm_velocity = -hurtbox_down * hitter.jump_impulse
	hitter.set_fast_falling(false)
	hitter.fastfall_depleted = true
	hitter.get_node("BounceTimer").start()
	
func release_orbs_and_destruct():
	for orb in $Orbs.get_children():
		$Orbs.remove_child(orb)
		orb.transform.origin += self.transform.origin + $Orbs.transform.origin
		get_parent().add_child(orb)
		orb.set_new_destination()
	
	is_opening = false
	get_parent().remove_child(self)
	queue_free()

func _on_animated_sprite_2d_animation_finished():
	if $AnimatedSprite2D.animation == "open":
		release_orbs_and_destruct()


func _on_animated_sprite_2d_animation_changed():
	if $AnimatedSprite2D.animation == "open":
		is_opening = true
