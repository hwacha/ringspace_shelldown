extends Control

var powerup_pos
var orb_scale
var t = 0
var t2 = 0

var can_start = false : set = set_can_start

func _ready():
	$Panel/Controls/RunAnimation/AnimatedSprite2D.play()
	$Panel/Controls/JumpAnimation/AnimatedSprite2D.play()
	$Panel/Controls/FastfallAnimation/AnimatedSprite2D.play()
	$Panel/Controls/FastfallAnimation/AnimatedSprite2D2.play()
	$Panel/Controls/UseAnimation/AnimatedSprite2D.play()
	
	$Panel2/HowToPlay/CenterContainer3/Kill/Player.play()
	
	$Panel/Controls/AnimationPlayer.play("controls")
	
	powerup_pos = $Panel/Controls/UseAnimation/Sprite2D.position
	orb_scale = $Panel2/HowToPlay/CenterContainer2/Collect/Orb.scale
	
	$Panel2/HowToPlay/CenterContainer3/Kill/Orbs.r = 30
	$Panel2/HowToPlay/CenterContainer3/Kill/Orbs2.r = 15
	
	for orbs in [
		$Panel2/HowToPlay/CenterContainer3/Kill/Orbs,
		$Panel2/HowToPlay/CenterContainer3/Kill/Orbs2
	]:
		for orb in orbs.get_children():
			orbs.on_add_orb(orb)
			
	$Panel2/HowToPlay/CenterContainer3/Kill/Orbs2.r = 15

func _process(delta):
	$Panel/Controls/UseAnimation/Sprite2D.position = powerup_pos + sin(t * 5) * Vector2(0, 1)
	
	for label in $Panel2/HowToPlay.get_children():
		label.get_child(0).get_node("Orb").scale = (1 + 0.08 * sin(t * 4)) * orb_scale
	
	t += delta
	
	
	if can_start:
		if Input.is_action_just_pressed("ui_accept"):
			get_tree().change_scene_to_file("res://scenes/main.tscn")
	
		var flash_t = 1 + cos(t2 * 3)
		$StartPrompt/RichTextLabel.modulate.a = flash_t
		$StartPrompt/Sprite2D.modulate.a = flash_t
		t2 += delta
	

func set_can_start(new_can_start):
	can_start = new_can_start
	$StartPrompt.visible = new_can_start

func _on_timer_timeout():
	can_start = true
