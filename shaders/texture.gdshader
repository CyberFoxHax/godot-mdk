shader_type spatial;

uniform sampler2D main_texture:source_color,filter_nearest;
uniform vec4 tint:source_color = vec4(0,0,0,0);

void fragment() {
	/*ivec2 s = textureSize(main_texture, 0);
	vec2 size = vec2(float(s.x), float(s.y));
	vec2 uv = UV;
	uv = round(uv*size)/size;*/
	vec2 uv = UV;
	vec4 c = texture(main_texture, uv);
	c+=tint;
	ALBEDO = c.rgb;
	ROUGHNESS = 1.0;
	SPECULAR = 0.02;
	//float avg = (c.r+c.g+c.b)/3.0;
	//ROUGHNESS = mix(0.2, 1.0, avg);
	//SPECULAR = mix(0.0, 0.5, avg);
}