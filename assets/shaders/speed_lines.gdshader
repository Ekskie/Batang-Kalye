shader_type canvas_item;

uniform float speed_intensity : hint_range(0.0, 1.0) = 0.0;
uniform vec4 line_color : source_color = vec4(1.0, 1.0, 1.0, 0.45);
uniform float line_density = 48.0;
uniform float inner_radius = 0.45;

float hash(vec2 p) {
	p = fract(p * vec2(123.34, 456.21));
	p += dot(p, p + 45.32);
	return fract(p.x * p.y);
}

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);

	float angle_id = floor((angle + 3.14159) * line_density);
	float rand_val = hash(vec2(angle_id, floor(TIME * 22.0)));

	float line_active = step(0.62, rand_val);
	float radial_fade = smoothstep(inner_radius, 0.82, dist);

	float alpha = line_active * radial_fade * speed_intensity * line_color.a;
	COLOR = vec4(line_color.rgb, alpha);
}
