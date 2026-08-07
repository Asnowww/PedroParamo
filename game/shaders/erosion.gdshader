shader_type canvas_item;
// 低语值侵蚀：波萨达版画式黑色刻线从画面边缘向中心啃噬。
// intensity 0..1 由代码驱动，只升不降。

uniform float intensity : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
    return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1, 0)), u.x),
               mix(hash(i + vec2(0, 1)), hash(i + vec2(1, 1)), u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int k = 0; k < 4; k++) {
        v += a * noise(p);
        p *= 2.1;
        a *= 0.5;
    }
    return v;
}

void fragment() {
    vec2 uv = UV;
    // 到最近边缘的距离（0=边缘, 0.5=中心）
    float edge = min(min(uv.x, 1.0 - uv.x), min(uv.y, 1.0 - uv.y));
    // 版画刻线感：细密平行排线 + 噪声扰动
    float lines = step(0.5, fract((uv.y + fbm(uv * 6.0) * 0.15) * 90.0));
    float creep = intensity * 0.5; // 侵蚀推进深度
    float n = fbm(uv * 5.0 + vec2(intensity * 2.0));
    float m = smoothstep(creep, creep - 0.18, edge + n * 0.12);
    float ink = m * (0.55 + 0.45 * lines);
    COLOR = vec4(0.04, 0.03, 0.02, ink * min(1.0, intensity * 1.6));
}
