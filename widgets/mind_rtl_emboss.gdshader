shader_type canvas_item;

uniform bool use_custom_color = false;
uniform vec4 emboss_color : source_color = vec4(0.0, 0.0, 0.0, 0.7);
uniform float darken_factor : hint_range(0.0, 1.0) = 0.3;

void fragment() {
	if (use_custom_color) {
		COLOR = vec4(emboss_color.rgb, COLOR.a * emboss_color.a);
	} else {
		COLOR.rgb *= darken_factor;
	}
}
