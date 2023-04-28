shader_type canvas_item;

uniform bool is_grabbable = false;

void vertex() {
	if (is_grabbable) {
		VERTEX *= 0.75 + 0.05 * sin(TIME * 5.0);
	}
}

void fragment() {
	
	// Place fragment code here.
}
