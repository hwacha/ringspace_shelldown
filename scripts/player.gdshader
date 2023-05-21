shader_type canvas_item;

uniform vec4 primary_color : source_color;
uniform bool is_invulnerable = false;
uniform int num_shields = 0;

const float intensity = 450.0;
const float precision = 0.1;

varying vec2 o;
varying vec2 f;

void fragment() {
	// shield outline
	if (num_shields > 0) {
		ivec2 t = textureSize(TEXTURE, 0);
		vec2 regular_uv;
		regular_uv.x = UV.x + (f.x - o.x)/float(t.x);
		regular_uv.y = UV.y + (f.y - o.y)/float(t.y);
		
		vec4 regular_color = texture(TEXTURE, regular_uv);
		if((regular_uv.x < 0.0 || regular_uv.x > 1.0) || (regular_uv.y < 0.0 || regular_uv.y > 1.0) || regular_color.a <=0.25){
			regular_color = vec4(0.0); 
		}
		
		vec2 ps = TEXTURE_PIXEL_SIZE * intensity * float(num_shields) * precision;
		
		vec4 final_color = regular_color;
		if (regular_color.a <= 0.0)
		{
			for(int x = -1; x <= 1; x += 1){
				for(int y = -1; y <= 1; y += 1){
					//Get the X and Y offset from this
					if (x==0 && y==0)
						continue;
						
					vec2 outline_uv = regular_uv + vec2(float(x) * ps.x, float(y) * ps.y); 
					
					//Sample here, if we are out of bounds then fail
					vec4 outline_sample = texture(TEXTURE, outline_uv);
					if((outline_uv.x < 0.0 || outline_uv.x > 1.0) || (outline_uv.y < 0.0 || outline_uv.y > 1.0)){
						//We aren't a real color
						outline_sample = vec4(0);
					}
					
					//Is our sample empty? Is there something nearby?
					if(outline_sample.a > final_color.a){
						final_color = primary_color + vec4(0.4, 0.4, 0.4, 0.0);
					}
				}
			}
		}
		COLOR = final_color;
	}

	
	// invulnerability
	if (is_invulnerable && texture(TEXTURE, UV).a > 0.0) {
		COLOR = primary_color;
		COLOR.a = 0.5;
		if (mod(TIME, 0.5) < 0.25) {
			COLOR.rgb = COLOR.rgb + vec3(0.2, 0.2, 0.2);
		}
	}
}
