extends Control

var powerup_pos
var orb_scale
var t = 0
var t2 = 0

var can_start = true : set = set_can_start

var run_last_frame = 0

func _ready():
	$ControlsPanel/MarginContainer/Controls/Fastfall/FastfallAnimation/Lines.play()
	$ControlsPanel/MarginContainer/Controls/AnimationPlayer.play("controls")
	
	powerup_pos = $ControlsPanel/MarginContainer/Controls/Use/UseAnimation/Powerup.position
	orb_scale = $HowToPanel/HowToPlay/CenterContainer2/Collect/Orb.scale
	
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs.r = 30
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs2.r = 15
	
	for orbs in [
		$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs,
		$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs2
	]:
		for orb in orbs.get_children():
			orbs.on_add_orb(orb)
			
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs2.r = 15

func _process(delta):
	$ControlsPanel/MarginContainer/Controls/Use/UseAnimation/Powerup.position = powerup_pos + sin(t * 5) * Vector2(0, 1)
	
	for label in $HowToPanel/HowToPlay.get_children():
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
	
func start_animations_and_set_shield_color(id : int):
	$ControlsPanel/MarginContainer/Controls/Run/RunAnimation/RunAnimation.play()
	$ControlsPanel/MarginContainer/Controls/Jump/JumpAnimation/JumpAnimation.play()
	$ControlsPanel/MarginContainer/Controls/Fastfall/FastfallAnimation/FastfallAnimation.play()
	$ControlsPanel/MarginContainer/Controls/Use/UseAnimation/UseAnimation.play()
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Player.play()
	
	$ControlsPanel/MarginContainer/Controls/Use/UseAnimation/UseAnimation.material\
		.set("shader_parameter/primary_color", Players.player_invulnerability_colors[id])
