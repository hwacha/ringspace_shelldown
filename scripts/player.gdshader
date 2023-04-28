shader_type canvas_item;

uniform vec4 primary_color : source_color;
uniform bool is_invulnerable = false;

void fragment() {
	if (is_invulnerable && texture(TEXTURE, UV).a > 0.0) {
		COLOR = primary_color;
		COLOR.a = 0.5;
		if (mod(TIME, 0.5) < 0.25) {
			COLOR.rgb = COLOR.rgb + vec3(0.2, 0.2, 0.2);
		}
	}
}
