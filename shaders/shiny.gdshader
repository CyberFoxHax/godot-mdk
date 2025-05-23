shader_type spatial;

uniform sampler2D main_texture:source_color;
uniform float reflection_offset_y;

void fragment() {
	vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz);
    float yaw = atan(camera_right.z, camera_right.x);

    vec3 camera_forward = normalize(CAMERA_DIRECTION_WORLD);
    float pitch = asin(camera_forward.y);
	pitch /= 2.;

	vec2 uv = SCREEN_UV*0.6+vec2(0.0, 0.2)+vec2(yaw/4.0, reflection_offset_y*50.0+pitch);
	
	ALBEDO = texture(main_texture, uv).rgb;
	float m = round(fract(uv.y/2.0));
	ALBEDO = mix(ALBEDO, texture(main_texture, vec2(uv.x, 1.0-uv.y)).rgb, m);
	
	ROUGHNESS = 1.0;
	SPECULAR = 0.1;
}