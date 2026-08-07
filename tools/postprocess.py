# -*- coding: utf-8 -*-
"""统一后期管线：把 art/backgrounds/ 的原图焊接成一体，输出 art/final/。

三线各自处理（SKILL.md 视觉体系）：
  present  -> 灰阶化 + 双色调（墓穴黑 #20242E -> 尘土黄暗部/热浪白高光）+ 强颗粒 + 暗角
  memory   -> 轻微暖色 LUT + 中颗粒 + 暗角（保留壁画饱和度）
  susana   -> 蓝色统一（普鲁士蓝基调收敛）+ 中颗粒 + 暗角
  woodcut/card/ui -> 纸纹颗粒 + 极轻暗角（不动色彩）
全部叠加统一的 amate 纸纹（程序化纤维噪声），保证混排一致。
"""
import os, sys, random
from PIL import Image, ImageOps, ImageEnhance, ImageFilter, ImageDraw

SRC = os.path.join(os.path.dirname(__file__), "..", "art", "backgrounds")
DST = os.path.join(os.path.dirname(__file__), "..", "art", "final")

# 双色调映射：暗部 -> 高光
DUO_SHADOW = (0x20, 0x24, 0x2E)   # 墓穴黑
DUO_MID    = (0xC9, 0xB4, 0x8F)   # 尘土黄
DUO_LIGHT  = (0xF0, 0xE8, 0xD6)   # 热浪白

def duotone(gray: Image.Image) -> Image.Image:
    lut = []
    for i in range(256):
        if i < 128:
            t = i / 127.0
            c = [int(DUO_SHADOW[k] + (DUO_MID[k] - DUO_SHADOW[k]) * t) for k in range(3)]
        else:
            t = (i - 128) / 127.0
            c = [int(DUO_MID[k] + (DUO_LIGHT[k] - DUO_MID[k]) * t) for k in range(3)]
        lut.append(tuple(c))
    r = gray.point([lut[i][0] for i in range(256)])
    g = gray.point([lut[i][1] for i in range(256)])
    b = gray.point([lut[i][2] for i in range(256)])
    return Image.merge("RGB", (r, g, b))

_paper_cache = {}
def paper(size):
    """程序化 amate 纸纹：低频斑驳 + 高频纤维，同尺寸缓存并全库复用（保证一致）。"""
    if size in _paper_cache:
        return _paper_cache[size]
    rnd = random.Random(1917)  # 固定种子：全部图共用同一张"纸"
    w, h = size
    low = Image.new("L", (w // 8, h // 8))
    low.putdata([rnd.randint(108, 148) for _ in range((w // 8) * (h // 8))])
    low = low.resize(size, Image.BILINEAR).filter(ImageFilter.GaussianBlur(2))
    hi = Image.new("L", size)
    hi.putdata([rnd.randint(96, 160) for _ in range(w * h)])
    hi = hi.filter(ImageFilter.GaussianBlur(0.5))
    tex = Image.blend(low, hi, 0.45)
    _paper_cache[size] = tex
    return tex

def grain(img: Image.Image, strength: float) -> Image.Image:
    tex = paper(img.size)
    overlay = ImageOps.colorize(tex, (0, 0, 0), (255, 255, 255))
    return Image.blend(img, Image.blend(img, overlay, 0.5), strength)

def vignette(img: Image.Image, strength: float) -> Image.Image:
    w, h = img.size
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.ellipse([-w * 0.25, -h * 0.25, w * 1.25, h * 1.25], fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(min(w, h) * 0.18))
    dark = ImageEnhance.Brightness(img).enhance(1.0 - strength)
    return Image.composite(img, dark, mask)

def process(name: str, img: Image.Image) -> Image.Image:
    img = img.convert("RGB")
    if name.startswith("present_"):
        g = ImageOps.autocontrast(ImageOps.grayscale(img), cutoff=1)
        img = duotone(g)
        img = grain(img, 0.10)
        img = vignette(img, 0.22)
    elif name.startswith("memory_"):
        img = ImageEnhance.Color(img).enhance(1.06)
        img = ImageEnhance.Contrast(img).enhance(1.03)
        img = grain(img, 0.07)
        img = vignette(img, 0.16)
    elif name.startswith("susana_"):
        r, g, b = img.split()
        img = Image.merge("RGB", (r.point(lambda v: int(v * 0.92)), g, b.point(lambda v: min(255, int(v * 1.05)))))
        img = grain(img, 0.07)
        img = vignette(img, 0.18)
    else:  # woodcut / card / ui / 其他
        img = grain(img, 0.05)
        img = vignette(img, 0.08)
    return img

def main():
    os.makedirs(DST, exist_ok=True)
    files = sorted(f for f in os.listdir(SRC) if f.endswith(".png") and not f.startswith("_"))
    done = 0
    for f in files:
        out = os.path.join(DST, f)
        if os.path.exists(out):
            continue
        img = Image.open(os.path.join(SRC, f))
        process(f, img).save(out)
        done += 1
        if done % 20 == 0:
            print(f"{done}/{len(files)}", flush=True)
    print(f"done: {done} new, {len(files)} total -> {DST}")

if __name__ == "__main__":
    main()
