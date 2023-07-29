shader_type canvas_item;

uniform bool is_black_hole_active = false;
uniform vec2 black_hole_center = vec2(540.0, 540.0);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

uniform float m = 0.008;

void fragment() {
	if (is_black_hole_active) {
		float pixel_size_proportion_y = 1.0 / (1080.0 * SCREEN_PIXEL_SIZE.y);
		float pixel_size_proportion_x = 1.0 / (1080.0 * SCREEN_PIXEL_SIZE.x);
		// get distance to black hole center in screen space
		vec2 screen_uv = FRAGCOORD.xy * SCREEN_PIXEL_SIZE;
		vec2 black_hole_center_uv = (black_hole_center + vec2(420.0, 0)) * vec2(pixel_size_proportion_x * SCREEN_PIXEL_SIZE.x, pixel_size_proportion_y * SCREEN_PIXEL_SIZE.y);
		float d = distance(vec2(screen_uv.x * 1920.0 / 1080.0, screen_uv.y), black_hole_center_uv);
		
		float pull_theta = m / (d * d);
	
		float _cos = cos(pull_theta * PI);
		
		vec2 diff = screen_uv - black_hole_center_uv;
		
		vec2 rot = vec2(_cos * diff.x + black_hole_center_uv.x, _cos * diff.y + black_hole_center_uv.y);
		COLOR = texture(SCREEN_TEXTURE, rot);
	}
	
}
