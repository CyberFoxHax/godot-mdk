shader_type spatial;

uniform sampler2D main_texture:source_color,filter_nearest;

void fragment() {
	vec4 c = texture(main_texture, UV);
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.05;
	//float avg = (c.r+c.g+c.b)/3.0;
	//ROUGHNESS = mix(0.2, 1.0, avg);
	//SPECULAR = mix(0.0, 0.5, avg);
}