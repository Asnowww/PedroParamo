shader_type canvas_item;
// 毛玻璃暗化：对身后的画面做高斯近似模糊，再压暗。
// 用在面板背后的全屏 ColorRect 上——面板本身在树中排它之后，所以不会被模糊。

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 12.0) = 5.0;
uniform float darken : hint_range(0.0, 1.0) = 0.62;
uniform vec3 tint : source_color = vec3(0.03, 0.028, 0.035);

void fragment() {
	vec2 px = SCREEN_PIXEL_SIZE * blur_amount;
	vec4 sum = vec4(0.0);
	// 13 抽样近似高斯（十字 + 对角 + 远环）
	sum += texture(SCREEN_TEXTURE, SCREEN_UV) * 0.1710;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x, 0.0)) * 0.1050;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(px.x, 0.0)) * 0.1050;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, px.y)) * 0.1050;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(0.0, px.y)) * 0.1050;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV + px * 1.6) * 0.0650;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV - px * 1.6) * 0.0650;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x, -px.y) * 1.6) * 0.0650;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-px.x, px.y) * 1.6) * 0.0650;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x * 3.2, 0.0)) * 0.0385;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(px.x * 3.2, 0.0)) * 0.0385;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, px.y * 3.2)) * 0.0385;
	sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(0.0, px.y * 3.2)) * 0.0385;
	COLOR = vec4(mix(sum.rgb, tint, darken), 1.0);
}
