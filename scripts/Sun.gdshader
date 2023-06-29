shader_type canvas_item;

uniform bool is_active = false;

void fragment() {
	if (is_active) {
		float wave_value = sin(TIME * 4.0);
		wave_value += sin(TIME * 6.0);
		wave_value += sin(TIME * 12.0);
		wave_value += sin(TIME * 24.0);
		wave_value *= 0.2;
		float inflection_point = 1.5;
		wave_value = wave_value + inflection_point;
		
		COLOR *= wave_value;
	}
}
