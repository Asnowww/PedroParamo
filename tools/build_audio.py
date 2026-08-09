# -*- coding: utf-8 -*-
"""把 Freesound CC0 素材裁切/调音/做无缝循环，输出到 game/assets/audio/"""
import subprocess, wave, os, sys, numpy as np
sys.stdout.reconfigure(encoding='utf-8')

FF = r"C:\Users\patri\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-7.1.1-full_build\bin\ffmpeg.exe"
SRC = "C:/Users/patri/AppData/Local/Temp/claude/C--Users-patri-OneDrive---bjtu-edu-cn-Files-----/fe395d98-7ab2-41f2-8806-9c4a75774737/scratchpad"
OUT = r"C:\Users\patri\OneDrive - bjtu.edu.cn\Files\大三暑假\pedro-paramo-game\game\assets\audio"
SR = 44100

def decode(mp3, start=None, dur=None, extra=None):
    """mp3 -> mono float32 numpy"""
    cmd = [FF, "-v", "error"]
    if start is not None: cmd += ["-ss", str(start)]
    if dur is not None:   cmd += ["-t", str(dur)]
    cmd += ["-i", mp3, "-ac", "1", "-ar", str(SR)]
    if extra: cmd += ["-af", extra]
    cmd += ["-f", "f32le", "-"]
    raw = subprocess.run(cmd, capture_output=True, check=True).stdout
    return np.frombuffer(raw, dtype=np.float32).astype(np.float64)

def norm(x, target_dbfs=-23.0, peak_ceiling=0.89):
    """按 RMS 对齐响度；个别瞬态用软拐点压回来，不牵连整体音量"""
    rms = np.sqrt(np.mean(x**2)) + 1e-12
    x = x * (10 ** (target_dbfs / 20.0) / rms)
    knee = peak_ceiling * 0.72
    over = np.abs(x) > knee
    if over.any():                           # 只压超过拐点的部分
        a = np.abs(x[over])
        x[over] = np.sign(x[over]) * (knee + (peak_ceiling - knee) * np.tanh((a - knee) / (peak_ceiling - knee)))
    return x

def seamless(x, fade_sec=2.0):
    """把尾巴淡入到头部，得到首尾相接不打嗝的循环"""
    n = int(fade_sec * SR)
    if len(x) < 3 * n: return x
    head, tail, mid = x[:n], x[-n:], x[n:-n]
    w = np.linspace(0, 1, n)
    joined = tail * (1 - w) + head * w       # 尾与头交叉淡化
    return np.concatenate([joined, mid])

def save(name, x):
    x = np.clip(x, -1, 1)
    path = os.path.join(OUT, name)
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x * 32767).astype(np.int16).tobytes())
    print(f"  {name}  {len(x)/SR:.1f}s  峰值 {np.abs(x).max():.2f}  RMS {20*np.log10(np.sqrt(np.mean(x**2))+1e-12):.1f} dBFS")

print("生成正式音效：")

# 1 雨：conleec 171980，取中段最稳的一截
save("lluvia_loop.wav", seamless(norm(decode(f"{SRC}/dl_171980.mp3", 40, 26), -24)))

# 2 钟：HMTSCCSound 554655 单记敲击 → 自排长间隔（远处、一下，又一下）
strike = decode(f"{SRC}/dl_554655.mp3", 0.42, 7.0, extra="lowpass=f=1800")   # 低通=推远
strike = norm(strike, -20)
strike *= np.minimum(1.0, np.linspace(0, 60, len(strike)))                    # 去掉起手咔哒
loop = np.zeros(int(26 * SR))
for t in (1.0, 9.5, 18.0):                                                    # 间隔 8.5 秒
    i = int(t * SR); loop[i:i+len(strike)] += strike
save("campana_loop.wav", norm(loop, -26, 0.85))

# 3 风：craigsmith 438869，用户指定从 1:00 起
save("viento_loop.wav", seamless(norm(decode(f"{SRC}/dl_438869.mp3", 60, 28), -24)))

# 4 低语：craigsmith 438384，用户指定 2.7s–18s
save("murmullo_loop.wav", seamless(norm(decode(f"{SRC}/dl_438384.mp3", 2.7, 15.3), -25), 1.5))

# 5 海：derjuli 824106
save("mar_loop.wav", seamless(norm(decode(f"{SRC}/dl_824106.mp3", 8, 28), -23)))

# 6 心跳：insaind 595050，放慢一档增加沉重感，响度拉高
beat = decode(f"{SRC}/dl_595050.mp3", extra="atempo=0.78,lowpass=f=320")
save("latido.wav", norm(np.tile(beat, 2), -15, 0.95))
