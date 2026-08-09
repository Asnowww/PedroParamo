# -*- coding: utf-8 -*-
"""增补五条环境音：合成/裁切 CC0 素材 -> game/assets/audio/
   与 build_audio.py 同一套响度与循环规范。"""
import subprocess, wave, os, sys, numpy as np
sys.stdout.reconfigure(encoding='utf-8')

FF  = r"C:\Users\patri\AppData\Local\Microsoft\WinGet\Packages\Gyan.FFmpeg_Microsoft.Winget.Source_8wekyb3d8bbwe\ffmpeg-7.1.1-full_build\bin\ffmpeg.exe"
SRC = "C:/Users/patri/AppData/Local/Temp/claude/C--Users-patri-OneDrive---bjtu-edu-cn-Files-----/fe395d98-7ab2-41f2-8806-9c4a75774737/scratchpad"
OUT = r"C:\Users\patri\OneDrive - bjtu.edu.cn\Files\大三暑假\pedro-paramo-game\game\assets\audio"
SR  = 44100

def decode(f, start=None, dur=None, af=None):
    cmd=[FF,"-v","error"]
    if start is not None: cmd+=["-ss",str(start)]
    if dur   is not None: cmd+=["-t",str(dur)]
    cmd+=["-i",f"{SRC}/{f}","-ac","1","-ar",str(SR)]
    if af: cmd+=["-af",af]
    cmd+=["-f","f32le","-"]
    return np.frombuffer(subprocess.run(cmd,capture_output=True,check=True).stdout,dtype=np.float32).astype(np.float64)

def norm(x, target=-24.0, ceil=0.89):
    x = x * (10**(target/20.0) / (np.sqrt(np.mean(x**2))+1e-12))
    knee = ceil*0.72; over = np.abs(x) > knee
    if over.any():
        a=np.abs(x[over])
        x[over]=np.sign(x[over])*(knee+(ceil-knee)*np.tanh((a-knee)/(ceil-knee)))
    return x

def seamless(x, fade=2.0):
    n=int(fade*SR)
    if len(x) < 3*n: return x
    w=np.linspace(0,1,n)
    return np.concatenate([x[-n:]*(1-w)+x[:n]*w, x[n:-n]])

def save(name, x):
    x=np.clip(x,-1,1)
    with wave.open(os.path.join(OUT,name),"w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR)
        w.writeframes((x*32767).astype(np.int16).tobytes())
    print(f"  {name:24s} {len(x)/SR:5.1f}s  峰值 {np.abs(x).max():.2f}  RMS {20*np.log10(np.sqrt(np.mean(x**2))+1e-12):.1f} dBFS")

print("生成增补环境音：")

# 1 空村的夜：干旱台地虫鸣打底 + 远处零星犬吠（合成，避开一切现代噪声）
bed = seamless(norm(decode("c_422582.mp3", 12, 44), -26))          # 拉扎克高原，低频干净
barks_src = norm(decode("c_698258.mp3", 63, 34, af="lowpass=f=2600"), -26)  # 低通=推远
village = bed.copy()
sb = int(SR*0.1)
for t_dst, t_src in ((6.5, 0.5), (17.0, 9.6), (28.5, 3.4), (37.0, 13.5)):   # 稀疏几声，别吵
    seg = barks_src[int(t_src*SR): int(t_src*SR)+int(2.2*SR)] * 0.34
    if len(seg) == 0: continue
    seg = seg * np.minimum(1, np.linspace(0, 30, len(seg))) * np.minimum(1, np.linspace(30, 0, len(seg)))
    i = int(t_dst*SR); n = min(len(seg), len(village)-i)
    village[i:i+n] += seg[:n]
save("pueblo_abandonado.wav", norm(village, -25))

# 2 蝉：普罗旺斯（低频 0.1%，全场最干净）
save("chicharras.wav", seamless(norm(decode("c_320113.mp3", 6, 26), -24)))

# 3 远处犬吠：单发，从犬吠最密的一段裁
save("perro_lejos.wav", norm(decode("c_698258.mp3", 65.5, 9, af="lowpass=f=2600"), -25, 0.85))

# 4 驴蹄：马蹄放慢成驴步，去掉尾巴
save("cascos.wav", seamless(norm(decode("c_479698.mp3", 0.2, 15, af="atempo=0.8"), -23), 1.2))

# 5 集市：塞维利亚游行铜管（推远压低）+ 西语人声集市铺底
brass = norm(decode("c_257671.mp3", 30, 30, af="lowpass=f=2400"), -30)
crowd = seamless(norm(decode("c_623605.mp3", 10, 30), -26))
n = min(len(brass), len(crowd))
save("feria.wav", norm(crowd[:n] + brass[:n], -23))
