extends GridContainer

var powerup_pos
var orb_scale
var t = 0

func _ready():
	$RunAnimation/AnimatedSprite2D.play()
	
	$JumpAnimation/AnimatedSprite2D.play()


	$FastfallAnimation/AnimatedSprite2D.play()
	$FastfallAnimation/AnimatedSprite2D2.play()
	
	$UseAnimation/AnimatedSprite2D.play()
	
	get_parent().get_node("Container/RichTextLabel3/AnimatedSprite2D").play()
	
	$AnimationPlayer.play("controls")
	
	powerup_pos = $UseAnimation/Sprite2D.position
	orb_scale = get_parent().get_node("Container/RichTextLabel/Orb").scale

func _process(delta):
	$UseAnimation/Sprite2D.position = powerup_pos + sin(t * 5) * Vector2(0, 1)
	
	for label in get_parent().get_node("Container").get_children():
		label.get_node("Orb").scale = (1 + 0.08 * sin(t * 4)) * orb_scale
	
	t += delta


func _on_timer_timeout():
	get_tree().change_scene_to_file("res://scenes/main.tscn")
