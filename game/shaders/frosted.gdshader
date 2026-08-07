shader_type canvas_item;
// 毛玻璃：对屏幕纹理做多次采样模糊，作为卡片详情的底

uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;
uniform float blur_amount : hint_range(0.0, 8.0) = 3.2;

void fragment() {
    vec2 px = SCREEN_PIXEL_SIZE * blur_amount;
    vec4 sum = vec4(0.0);
    // 13 抽样近似高斯
    sum += texture(SCREEN_TEXTURE, SCREEN_UV) * 0.196;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x, 0.0)) * 0.118;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(px.x, 0.0)) * 0.118;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, px.y)) * 0.118;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(0.0, px.y)) * 0.118;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + px * 2.0) * 0.066;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV - px * 2.0) * 0.066;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x, -px.y) * 2.0) * 0.066;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(-px.x, px.y) * 2.0) * 0.066;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(px.x * 4.0, 0.0)) * 0.0295;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(px.x * 4.0, 0.0)) * 0.0295;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, px.y * 4.0)) * 0.0295;
    sum += texture(SCREEN_TEXTURE, SCREEN_UV - vec2(0.0, px.y * 4.0)) * 0.0295;
    COLOR = vec4(mix(sum.rgb, vec3(0.06, 0.05, 0.05), 0.35), 1.0);
}
