shader_type canvas_item;

// Worn paint for stencil text on the steel plates: speckled chips knocked out
// of the strokes plus a little tone variation. Screen-space so every label
// shares one wear pattern.
uniform sampler2D wear : repeat_enable, filter_linear;
uniform float wear_scale = 0.018;
uniform float chip = 0.22;

void fragment() {
	vec4 c = COLOR;
	float n = texture(wear, FRAGCOORD.xy * wear_scale).r;
	float fine = texture(wear, FRAGCOORD.xy * wear_scale * 4.3 + vec2(0.37, 0.71)).r;
	float keep = smoothstep(chip - 0.06, chip + 0.06, n * 0.6 + fine * 0.4);
	c.a *= mix(0.25, 1.0, keep);
	c.rgb *= mix(0.80, 1.04, fine);
	COLOR = c;
}
