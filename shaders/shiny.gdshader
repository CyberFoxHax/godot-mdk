shader_type spatial;

uniform sampler2D main_texture:source_color;
uniform float reflection_offset_y;

void fragment() {
	vec3 camera_right = normalize(INV_VIEW_MATRIX[0].xyz);
    float yaw = atan(camera_right.z, camera_right.x);

    vec3 camera_forward = normalize(CAMERA_DIRECTION_WORLD);
    float pitch = asin(camera_forward.y);
	pitch = clamp(pitch, -0.65, 0.60);
	pitch /= 3.;

	ALBEDO = texture(main_texture, SCREEN_UV*0.6+vec2(0.0, 0.2)+vec2(yaw/4.0, reflection_offset_y*50.0+pitch)).rgb;
	
	ROUGHNESS = 1.0; 
	SPECULAR = 0.1;
}