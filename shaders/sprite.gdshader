shader_type spatial;

uniform sampler2D main_texture:source_color;
uniform int frame_count;
uniform vec4 frame_rects[64];
uniform vec2 frame_margins[64];

void fragment() {
	float time = TIME*0.1;
	int frame = int(floor(time*float(frame_count))) % frame_count;
	
	vec4 frame_rect = frame_rects[frame];

	vec2 uv1 = UV*frame_rect.zw + frame_rect.xy;

	vec4 c = texture(main_texture, uv1);
    ALBEDO = c.rgb;
	ALPHA = c.a;
}

//void light() {
//	COLOR.rgb += LIGHT;
//}
