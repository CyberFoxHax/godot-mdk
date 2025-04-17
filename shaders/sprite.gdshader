shader_type spatial;

uniform sampler2D main_texture : source_color;
uniform int frame_count;
uniform vec4 frame_rects[64];
uniform vec2 frame_margins[64];
uniform vec2 largest_frame;

float isBetween01(float x) {
    return step(0.0, x) * (1.0 - step(1.0, x));
}

vec3 get_frame_uv(vec2 p, int frame){
    vec4 frame_rect = frame_rects[frame];
    vec2 frame_margin = frame_margins[frame];

    vec2 original_size = frame_rect.zw; // Store original size for masking
    float original_x_start = frame_rect.x; // Store original x offset

    // Adjust frame_rect to match largest_frame dimensions
    vec2 diff = largest_frame - frame_rect.zw;
    diff.y = 0.3; // Only adjust width, not height
    frame_rect.zw += diff;
    frame_rect.xy -= diff / 2.0;

    // Calculate UVs for texture sampling
    vec2 uv = p * frame_rect.zw + frame_rect.xy + frame_margin/2.0 - vec2(0.01, 0.05);

    // Calculate mask based on original frame bounds
    vec2 mask;
    mask.x = isBetween01((uv.x - original_x_start) / original_size.x);
    mask.y = isBetween01(uv.y / original_size.y); 

    return vec3(uv, mask.x*mask.y);
}

void fragment() {
    float time = TIME * 30.0;
    int frame = int(floor(time)) % frame_count;
    int frame_next = int(floor(time)+1.0) % frame_count;
    vec3 uv = get_frame_uv(UV, frame);
    vec3 uv2 = get_frame_uv(UV, frame_next);

    // linear frame interpolation for 60fps
    vec4 a = texture(main_texture, uv.xy);
    vec4 b = texture(main_texture, uv2.xy);
    vec4 c = mix(a,b, fract(time));

    ALBEDO = c.rgb;
    ALPHA = c.a * uv.z; // Mask out pixels outside original frame bounds
}
 
void light(){
    DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * ATTENUATION * LIGHT_COLOR / PI;

    DIFFUSE_LIGHT *= 0.8;
    DIFFUSE_LIGHT += 0.5;
}