shader_type spatial;
render_mode unshaded, depth_draw_never, depth_test_disabled, fog_disabled, cull_disabled;

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

uniform vec4 outline_color : source_color = vec4(0.08, 0.08, 0.12, 1.0);
uniform float outline_thickness : hint_range(0.5, 4.0) = 1.35;
uniform float depth_threshold : hint_range(0.05, 2.0) = 0.42;
uniform float normal_threshold : hint_range(0.05, 1.0) = 0.52;
uniform float color_threshold : hint_range(0.02, 1.0) = 0.25;

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

vec3 get_view_pos(vec2 uv, mat4 inv_proj) {
	float d = texture(depth_texture, uv).r;
	vec3 ndc = vec3(uv * 2.0 - 1.0, d);
	vec4 v = inv_proj * vec4(ndc, 1.0);
	return v.xyz / max(abs(v.w), 0.00001);
}

float get_lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

void fragment() {
	vec2 texel = vec2(outline_thickness) / VIEWPORT_SIZE;
	vec4 center_col = texture(screen_texture, SCREEN_UV);
	float center_d = texture(depth_texture, SCREEN_UV).r;

	// In Godot 4.3+ reverse-Z: 0.0 is sky/far plane. 1.0 is near plane.
	if (center_d <= 0.00005 || center_d >= 0.99995) {
		ALBEDO = center_col.rgb;
	} else {
		vec3 p0 = get_view_pos(SCREEN_UV, INV_PROJECTION_MATRIX);

		// Sample 4 cross points
		vec2 uv_u = SCREEN_UV + vec2(0.0, -texel.y);
		vec2 uv_d = SCREEN_UV + vec2(0.0,  texel.y);
		vec2 uv_l = SCREEN_UV + vec2(-texel.x, 0.0);
		vec2 uv_r = SCREEN_UV + vec2( texel.x, 0.0);

		vec3 pu = get_view_pos(uv_u, INV_PROJECTION_MATRIX);
		vec3 pd = get_view_pos(uv_d, INV_PROJECTION_MATRIX);
		vec3 pl = get_view_pos(uv_l, INV_PROJECTION_MATRIX);
		vec3 pr = get_view_pos(uv_r, INV_PROJECTION_MATRIX);

		// Surface normal at center pixel
		vec3 dx = pr - pl;
		vec3 dy = pd - pu;
		vec3 n0 = cross(dy, dx);
		float n_len = length(n0);
		if (n_len > 0.0001) {
			n0 /= n_len;
		} else {
			n0 = normalize(cross(dFdy(p0), dFdx(p0)));
		}

		// 1. Plane-distance depth discontinuity test
		float dist_u = abs(dot(pu - p0, n0));
		float dist_d = abs(dot(pd - p0, n0));
		float dist_l = abs(dot(pl - p0, n0));
		float dist_r = abs(dot(pr - p0, n0));
		float max_dist = max(max(dist_u, dist_d), max(dist_l, dist_r));

		float view_dist = length(p0);
		float adaptive_depth_thresh = depth_threshold * max(1.0, view_dist * 0.06);
		float depth_edge = step(adaptive_depth_thresh, max_dist);

		// 2. Color / Luminance edge test
		vec3 cu = texture(screen_texture, uv_u).rgb;
		vec3 cd = texture(screen_texture, uv_d).rgb;
		vec3 cl = texture(screen_texture, uv_l).rgb;
		vec3 cr = texture(screen_texture, uv_r).rgb;

		float lum_grad = abs(get_lum(cr) - get_lum(cl)) + abs(get_lum(cd) - get_lum(cu));
		float color_edge = step(color_threshold, lum_grad);

		// 3. Normal direction change test
		vec3 nu = cross(dFdy(pu), dFdx(pu));
		vec3 nd = cross(dFdy(pd), dFdx(pd));
		float norm_diff = 0.0;
		if (length(nu) > 0.0001) {
			norm_diff = max(norm_diff, 1.0 - clamp(dot(n0, normalize(nu)), -1.0, 1.0));
		}
		if (length(nd) > 0.0001) {
			norm_diff = max(norm_diff, 1.0 - clamp(dot(n0, normalize(nd)), -1.0, 1.0));
		}
		float norm_edge = step(normal_threshold, norm_diff);

		float edge = clamp(depth_edge + norm_edge * 0.8 + color_edge * 0.5, 0.0, 1.0);

		ALBEDO = mix(center_col.rgb, outline_color.rgb, edge);
	}
}
