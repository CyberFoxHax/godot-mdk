shader_type spatial;

uniform vec4 main_color;

void fragment() {
	ALBEDO = main_color.rgb;
	ALPHA = main_color.a/3.0;
	ROUGHNESS = 1.0;
	SPECULAR = 0.2;
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
