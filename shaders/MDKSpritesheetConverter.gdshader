shader_type canvas_item;

uniform vec4 palette[256];
uniform sampler2D main_texture:source_color,filter_nearest;
uniform int tranparent_index = 0;

void fragment() {
    int index = int(texture(main_texture, UV).r * 255.0);
    float distance = length(float(index - tranparent_index));
    float blend = step(0.01, distance);

    int palette_idx = index;
	vec4 c = palette[palette_idx];
	COLOR = mix(vec4(0,0,0,0), c, blend);
}