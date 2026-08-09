# 正式音效候选清单（待用户审核）

**筛选原则**

1. **只收 CC0**（Creative Commons 0 / 公有领域）——不需署名、可商用、以后要发布也没有后患。
   Freesound 上还有 CC BY 和 CC BY-NC 的素材，本清单一律不收，避免将来清权。
2. 优先**田野实录**而非合成音，优先**拉美/干旱地带**的录音，宁可素一点，不要"电影感"的加工音。
3. 每条给一个主选 + 一个备选，主选不合意就用备选，不必回头再找。

**下载与替换方式**（选定后）

Freesound 需注册免费账号才能下载。下载后转成 wav、按下表的文件名覆盖
`game/assets/audio/` 里的同名占位文件即可，**代码一行都不用改**。

---

## 一、当前系统实际调用的六条（优先级最高）

| 文件名 | 用在哪 | 主选 | 备选 |
|---|---|---|---|
| `lluvia_loop.wav` | F34 坟中听雨（倾听声源）、雨夜场景 | [conleec – AMB_M_City_Rain_Light](https://freesound.org/people/conleec/sounds/171980/) 庭院里的小雨，不吵，贴合"檐水滴进水缸" | [seth-m – light rain and crickets](https://freesound.org/people/seth-m/sounds/323426/) 作者注明可无缝循环 |
| `campana_loop.wav` | F34 远钟、F55 三日钟声 | [HMTSCCSound – bec low bell solo](https://freesound.org/people/HMTSCCSound/sounds/554655/) 单口低音钟、绳拉、自然收尾——正是"很远的地方，一下，又一下" | [Zabuhailo – ChurchBells](https://freesound.org/people/Zabuhailo/sounds/178648/) 7分钟整段，可裁 F55 的钟声狂欢 |
| `viento_loop.wav` | F34 富尔戈尔声源、旷野与夜风 | [felix.blume – Dry grass rustling in the wind, desert of Chile](https://freesound.org/people/felix.blume/sounds/146436/) **智利沙漠实录**，干草与风，气质最接近科马拉 | [craigsmith – G56-14 Dry Wind Gusts](https://freesound.org/people/craigsmith/sounds/438869/) 荒原阵风，低频更足 |
| `murmullo_loop.wav` | F45 缠人的杂音低语、全片"嗡嗡声" | [craigsmith – G28-24 Whispering Crowd Walla](https://freesound.org/people/craigsmith/sounds/438384/) 作者原话：人群其实在耳语。老录音的底噪反而对味 | [kyles – crowd light whisper murmur hush](https://freesound.org/people/kyles/sounds/452955/) 更干净、空间更大 |
| `mar_loop.wav` | F45 苏萨娜的海（她唯一"湿"的声音） | [ClubsHeartsSpadesDiamonds – Relaxing Beach Waves](https://freesound.org/people/ClubsHeartsSpadesDiamonds/sounds/325197/) 轻浪拍岸，配"浪先湿了脚踝" | [derjuli – NorthSeaWaves](https://freesound.org/people/derjuli/sounds/824106/) 更沉、更冷 |
| `latido.wav` | 中点死亡过场 | [patobottos – Heartbeats 61](https://freesound.org/people/patobottos/sounds/369017/) 真人心跳约61bpm，5万+下载的老牌素材 | [loudernoises – heartbeat-60bpm](https://freesound.org/people/loudernoises/sounds/332821/) 合成音，更干净可控 |

## 二、建议增补的六条（能明显提升沉浸感，代码需加几行）

| 建议文件名 | 用在哪 | 候选 |
|---|---|---|
| `pueblo_abandonado.wav` | 上半场空村的底噪（风+虫+远处狗） | [felix.blume – Village ambiance with wind in an abandoned house](https://freesound.org/people/felix.blume/sounds/667755/) 废弃屋里的风、鸟、虫——几乎是为科马拉录的 |
| `feria.wav` | F55 钟声引来的狂欢集市 | [khenshom – Weekend Fair in Chapultepec Park](https://freesound.org/people/khenshom/sounds/623605/) 墨西哥城实录集市，西语人声与小贩 |
| `calle_mexicana.wav` | 街道/广场（有人的年代） | [greysound – SMA Announcement Car](https://freesound.org/people/greysound/sounds/547918/) 圣米格尔小镇街景 |
| `cascos.wav` | 序章驴蹄声（阿文迪奥同行） | Freesound 用 `hooves dirt` + CC0 过滤；备用 [Pixabay 蹄声](https://pixabay.com/sound-effects/search/hooves/)（免署名） |
| `perro_lejos.wav` | F24 空街狗吠 | Freesound `dog bark distant` + CC0 过滤 |
| `chicharras.wav` | 八月盛暑的蝉（闷热之夜） | Freesound `cicadas heat` + CC0 过滤；felix.blume 有多条拉美虫鸣 |

## 三、备用素材站（万一 Freesound 找不到）

| 站点 | 授权 | 说明 |
|---|---|---|
| [Pixabay Sound Effects](https://pixabay.com/sound-effects/) | Pixabay 授权 | 免署名、可商用，注册即下，质量参差但量大 |
| [Mixkit](https://mixkit.co/free-sound-effects/) | Mixkit 免费授权 | 免署名，分类干净 |
| [OpenGameArt](https://opengameart.org/) | 含大量 CC0 | 游戏向，可按 CC0 过滤 |
| [ZapSplat](https://www.zapsplat.com/) | 免费需署名 | **需署名**，本项目尽量不用 |
| BBC Sound Effects | RemArc 授权 | **仅限个人/教育，禁商用**——demo 可用，将来发布要换 |

## 四、给用户的审核建议

1. 先只听**第一组六条**的主选，觉得不对就点备选；这六条决定了游戏 80% 的听感。
2. 重点听两条：`viento_loop`（决定荒凉感）和 `murmullo_loop`（决定恐怖感）。这两条对了，其余都是配角。
3. 第二组是加分项，你觉得没必要可以整组砍掉，不影响现有流程。
4. 选定后告诉我编号，我来下载、裁切、做循环点、统一响度（-20 LUFS 左右），再替换进工程。
