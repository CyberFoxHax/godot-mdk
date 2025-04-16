shader_type spatial;

uniform sampler2D main_texture:source_color, filter_nearest;
uniform vec2 pixels_size;

void fragment() {
	vec4 c = texture(main_texture, UV);
	float distance = length(c - vec4(1,0,1,1));
    float blend = step(1, distance);
    ALBEDO = c.rgb;
	ALPHA = blend;
}

//void light() {
//	COLOR.rgb += LIGHT;
//}
