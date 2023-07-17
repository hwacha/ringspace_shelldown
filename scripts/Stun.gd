extends Sprite2D

var t = 0

func _ready():
	pass


func _process(delta):
	if t > 0.25:
		flip_v = not flip_v
		if flip_v:
			scale.x = 0.14
		else:
			scale.x = 0.12
		t = 0
		
	t += delta
