extends RichTextLabel

var final_time = 0

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var timer = get_node("../MatchTimer")
	var time_left = timer.get_time_left()
	if timer.is_stopped():
		text = str(ceil(final_time))
	else:
		text = str(ceil(time_left))
