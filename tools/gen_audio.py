# -*- coding: utf-8 -*-
"""程序化占位音频：坟中倾听系统的可听原型。
正式音效待用户从 CC0 库选型后替换（同名覆盖 game/assets/audio/ 即可）。
"""
import numpy as np, wave, os

SR = 44100
OUT = os.path.join(os.path.dirname(__file__), "..", "game", "assets", "audio")

def save(name, x):
    x = np.clip(x, -1, 1)
    os.makedirs(OUT, exist_ok=True)
    with wave.open(os.path.join(OUT, name), "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print("saved", name)

def env(n, a=0.01, r=0.5):
    e = np.ones(n); na, nr = int(a * SR), int(r * SR)
    e[:na] = np.linspace(0, 1, na); e[-nr:] = np.linspace(1, 0, nr)
    return e

rng = np.random.default_rng(1955)

# 雨：过滤噪声 + 随机雨滴嘀嗒
n = SR * 8
rain = rng.normal(0, 0.12, n)
rain = np.convolve(rain, np.ones(24) / 24, "same")            # 闷化
for _ in range(260):                                            # 雨滴
    p = rng.integers(0, n - 2000); d = rng.integers(300, 1800)
    rain[p:p+d] += np.sin(np.linspace(0, np.pi, d)) * rng.uniform(0.05, 0.22) * rng.choice([1, -1])
save("lluvia_loop.wav", rain * env(n, 0.2, 0.2))

# 远钟：衰减泛音列，每 4 秒一响
n = SR * 8
t = np.arange(n) / SR
bell = np.zeros(n)
for start in (0.5, 4.5):
    seg = t - start
    m = seg > 0
    for f, a in ((196, .5), (392, .3), (587, .18), (784, .1), (988, .06)):
        bell[m] += a * np.sin(2*np.pi*f*seg[m]) * np.exp(-seg[m]*1.4)
save("campana_loop.wav", bell * 0.5)

# 风：慢调制的宽带噪声
n = SR * 8
wind = rng.normal(0, 0.2, n)
wind = np.convolve(wind, np.ones(60)/60, "same")
lfo = 0.55 + 0.45*np.sin(2*np.pi*0.13*np.arange(n)/SR + 1.2)
save("viento_loop.wav", wind * lfo * env(n, .3, .3))

# 低语群：多层带通噪声窃窃私语（无词义）
n = SR * 8
mur = np.zeros(n)
for _ in range(9):
    v = rng.normal(0, 0.5, n)
    v = np.convolve(v, np.ones(10)/10, "same") - np.convolve(v, np.ones(90)/90, "same")
    syl = np.clip(np.sin(2*np.pi*rng.uniform(2.2, 3.8)*np.arange(n)/SR + rng.uniform(0, 6)), 0, 1)
    mur += v * syl * rng.uniform(0.05, 0.1)
save("murmullo_loop.wav", mur * env(n, .4, .4))

# 海：长波涌
n = SR * 10
sea = rng.normal(0, 0.16, n)
sea = np.convolve(sea, np.ones(40)/40, "same")
swell = 0.35 + 0.65*np.clip(np.sin(2*np.pi*0.09*np.arange(n)/SR), -0.2, 1)
save("mar_loop.wav", sea * swell * env(n, .5, .5))

# 心跳（死亡演出用）：双峰低频
n = SR * 6
t = np.arange(n)/SR
hb = np.zeros(n)
for b in np.arange(0.2, 5.6, 0.85):
    for off, amp in ((0.0, 1.0), (0.18, 0.6)):
        seg = t - (b + off); m = (seg > 0) & (seg < 0.12)
        hb[m] += amp * np.sin(2*np.pi*52*seg[m]) * np.exp(-seg[m]*40)
save("latido.wav", hb * 0.8)
print("done")
