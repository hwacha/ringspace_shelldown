extends Control

var powerup_pos
var orb_scale
var t = 0

var cur_id = 0

var run_last_frame = 0

@export var dir : int

func _ready():
	$ControlsPanel/MarginContainer/Controls/Fastfall/FastfallAnimation/Lines.play()
	$ControlsPanel/MarginContainer/Controls/AnimationPlayer.play("controls")
	
	powerup_pos = $ControlsPanel/MarginContainer/Controls/Use/UseAnimation/Powerup.position
	orb_scale = $HowToPanel/HowToPlay/CenterContainer2/Collect/Orb.scale
	
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs.r = 30
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs.dir = dir
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs2.r = 15
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Orbs2.dir = dir
	
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
		var orb = label.get_child(0).get_node_or_null("Orb")
		if orb != null:
			orb.scale = (1 + 0.08 * sin(t * 4)) * orb_scale
	
	t += delta
	
func start_animations_and_set_shield_color(id : int):
	cur_id = id
	queue_redraw()
	$ControlsPanel/MarginContainer/Controls/Run/RunAnimation/RunAnimation.play()
	$ControlsPanel/MarginContainer/Controls/Jump/JumpAnimation/JumpAnimation.play()
	$ControlsPanel/MarginContainer/Controls/Fastfall/FastfallAnimation/FastfallAnimation.play()
	$ControlsPanel/MarginContainer/Controls/Use/UseAnimation/UseAnimation.play()
	$HowToPanel/HowToPlay/CenterContainer3/Kill/Player.play()
	
	$ControlsPanel/MarginContainer/Controls/Use/UseAnimation/UseAnimation.material\
		.set("shader_parameter/primary_color", Players.player_invulnerability_colors[id])

func _draw():
	var epsilon = 0.03
	var theta = 2 * PI / Players.play_to
	for i in range(0, Players.play_to):
		draw_arc(Vector2(1673, 771), 30, \
				(i * theta) + epsilon, ((i + 1) * theta) - epsilon, 100, Players.player_colors[cur_id], 7)
