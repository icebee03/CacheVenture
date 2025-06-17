shader_type canvas_item;
uniform float opacity : hint_range(0.0, 1.0) = 1.0;
uniform float mix_color : hint_range(0.0, 1.0) = 0.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// base color (rendered by Control node)
	vec4 base = COLOR;
	
	// green color to mix in with opacity 1 (last argument)
	vec4 green = vec4(0.0, 1.0, 0.0, opacity);
	
	// blend base with green
	COLOR = mix(base, green, mix_color);
}
