shader_type spatial;

uniform vec4 main_color:source_color;

void fragment() {
	ALBEDO = main_color.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.01;
}