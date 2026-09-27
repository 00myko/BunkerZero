shader_type canvas_item;

uniform vec4 edge_red : source_color = vec4(0.42, 0.0, 0.0, 1.0);
uniform float edge_strength : hint_range(0.0, 1.0) = 0.64;
uniform float darkness : hint_range(0.0, 1.0) = 0.22;

void fragment() {
	vec2 centered = UV * 2.0 - 1.0;
	float radial = smoothstep(0.30, 1.15, length(centered * vec2(0.84, 1.0)));
	float lower = smoothstep(-0.3, 0.9, centered.y) * 0.08;
	vec3 tint = mix(vec3(0.0), edge_red.rgb, radial * edge_strength);
	float alpha = clamp(radial * 0.58 + darkness * 0.28 + lower, 0.0, 0.74);
	COLOR = vec4(tint, alpha);
}
