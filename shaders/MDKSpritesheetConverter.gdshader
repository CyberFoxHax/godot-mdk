///// Shader to apply palette to texture
shader_type canvas_item;

uniform vec4 palette[256];
uniform sampler2D main_texture:source_color,filter_nearest;

void fragment() {
    float index = texture(main_texture, UV).r * 255.0;
    int palette_idx = int(index);
	vec4 c = palette[palette_idx];
    float distance = length(c - vec4(1,0,1,1));
    float blend = step(0.01, distance);
	COLOR = mix(vec4(0,0,0,0), c, blend);
}