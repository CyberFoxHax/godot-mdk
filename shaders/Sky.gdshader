shader_type sky;

uniform sampler2D tex;
uniform float rotation = 0;
uniform vec2 tile = vec2(2.0, 3.0);
uniform vec2 offset = vec2(0.0, 0.0);

void sky() {
	float cos_rot = cos(rotation);
    float sin_rot = sin(rotation);
    vec3 rotated_dir = vec3(
        EYEDIR.x * cos_rot + EYEDIR.z * sin_rot,  // X component
        EYEDIR.y,                              // Y unchanged (vertical axis)
        -EYEDIR.x * sin_rot + EYEDIR.z * cos_rot  // Z component
    );
	
	// equirectangular coordinates
	vec2 uv = vec2(
        atan(rotated_dir.x, rotated_dir.z) / (2.0 * 3.14159265358979323846),
        acos(rotated_dir.y) / 3.14159265358979323846
    );
	
	uv = uv*tile+offset;
	uv.y = clamp(uv.y, 0.01, 0.99);
    
	COLOR = texture(tex, uv).rgb;
	COLOR = pow(COLOR, vec3(2.0));
}
