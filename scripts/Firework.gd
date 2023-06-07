extends Path2D

var speed = 1.5

@export var active : bool = false : set = _set_active
var locked = false

#func _ready():
#	pass

func _set_active(new_active):
	visible = new_active
	active = new_active
	
	if not active:
		$PathFollow2D/Bomb.visible = true
		$PathFollow2D/Explosion.emitting = false
		$PathFollow2D.progress_ratio = 0
		locked = false

func _process(delta):
	if active:
		if $PathFollow2D.progress_ratio < 1:
			$PathFollow2D.progress_ratio += speed * delta
		elif not locked:
			$PathFollow2D/Bomb.visible = false
			$PathFollow2D/Explosion.restart()
			$PathFollow2D/Explosion.emitting = true
			locked = true
