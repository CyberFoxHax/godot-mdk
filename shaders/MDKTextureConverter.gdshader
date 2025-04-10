///// Shader to apply palette to texture 
shader_type canvas_item;

uniform vec4 palette[256];
uniform vec2 pixels_size;
uniform sampler2D pixels;

void fragment() {
    float index = texture(pixels, UV).r * 255.0;
    int palette_idx = int(index);
	COLOR = palette[palette_idx];
}