shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear_mipmap;
uniform float blur_lod : hint_range(0.0, 5.0) = 1.55;
uniform vec4 glass_tint : source_color = vec4(0.010, 0.008, 0.008, 0.43);
uniform float desaturate : hint_range(0.0, 1.0) = 0.14;
uniform float contrast : hint_range(0.5, 1.5) = 0.94;
uniform float corner_cut : hint_range(0.0, 0.12) = 0.030;

float gaussian_line(float x, float center, float width) {
	float d = (x - center) / width;
	return exp(-d * d);
}

void fragment() {
	// Cut/chamfer the four corners to match the approved concept.
	if ((UV.x + UV.y) < corner_cut ||
		((1.0 - UV.x) + UV.y) < corner_cut ||
		(UV.x + (1.0 - UV.y)) < corner_cut ||
		((1.0 - UV.x) + (1.0 - UV.y)) < corner_cut) {
		discard;
	}

	vec4 scene = textureLod(screen_texture, SCREEN_UV, blur_lod);
	float gray = dot(scene.rgb, vec3(0.299, 0.587, 0.114));
	scene.rgb = mix(scene.rgb, vec3(gray), desaturate);
	scene.rgb = (scene.rgb - vec3(0.5)) * contrast + vec3(0.5);

	// Neutral black/charcoal glass, not blue.
	vec3 tinted = mix(scene.rgb, glass_tint.rgb, glass_tint.a);

	// Very faint translucent red vertical streaks inside the glass.
	float red_lines = 0.0;
	red_lines += gaussian_line(UV.x, 0.292, 0.007) * 0.16;
	red_lines += gaussian_line(UV.x, 0.315, 0.012) * 0.07;
	red_lines += gaussian_line(UV.x, 0.695, 0.008) * 0.06;
	tinted += vec3(0.34, 0.015, 0.008) * red_lines;

	COLOR = vec4(tinted, 0.87);
}
