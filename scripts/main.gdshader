shader_type canvas_item;

void fragment() {
	if (COLOR.rgb == vec3(0.0, 0.0, 0.0)) {
		COLOR.rgb = vec3(0.025, 0.025, 0.025);
	}
}
