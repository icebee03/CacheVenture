shader_type canvas_item;
uniform float opacity;
uniform float red;
uniform float green;
uniform float blue;
uniform float mix_color;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 texture_color = texture(TEXTURE, UV);
	if (texture_color.a != 0.0)
		COLOR = vec4(mix(texture_color.rgb, vec3(red, green, blue), mix_color), opacity);
}
