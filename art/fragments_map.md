# 《佩德罗·巴拉莫》60 碎片对照表（碎片 × 剧情 × 卡牌 × 美术资产）

> 剧情来源：`text/pedro_tu.txt`（译林社屠孟超译本 Calibre 转换件），行号 L 与文件严格对应。
> 本译本正文实际为 **60 个碎片**（按双空行分隔程序化切分，此前设计按"约70"估算——以本表为准）。
> 游戏章节按 SKILL.md 八章结构；【回忆】=上半场插叙的佩德罗线碎片。

## 资产命名规则（防丢失约定）

- **碎片编号 `F01–F60`**：阅读顺序编号，对应本表行号范围，是全项目唯一叙事索引。
- **卡牌 `card_<NN>_<西语slug>.png`**：NN 为拼图板簇内固定序号（**不是**碎片号！），卡↔碎片的绑定只认本表和 `manifest.csv`。
- **背景/CG `<前缀>_<场景slug>_<序号>.png`**：前缀六种 = `present`（摄影线）/`memory`（壁画线）/`susana`（蓝晒线）/`woodcut`（版画线）/`card`（卡牌）/`ui`（系统）。
- 查找方向：**由碎片找资产** → 查本表或 `manifest.csv`；**由资产反查碎片** → 用文件名 slug 在本表全文检索。
- 引擎接入时以 `manifest.csv` 为唯一数据源，本表为人读版。

## 拼图板分簇（9 簇 70 卡）

| 簇 | 卡牌范围 | 主题 |
|---|---|---|
| C1 童年 | card_01–08 | 佩德罗与苏萨娜的童年 |
| C2 到达与回声 | card_09–16, 60, 62, 65 | 胡安入村与鬼村感知 |
| C3 米盖尔与神父 | card_17–24 | 米盖尔之罪与雷德里亚的挣扎 |
| C4 半月庄崛起 | card_25–32 | 婚姻、吞地、处刑 |
| C5 坟中 | card_33–38 | 死后倾听 |
| C6 苏萨娜 | card_39–50 | 归来、疯狂、海、死亡 |
| C7 革命 | card_51–56 | 富尔戈尔之死与蒂尔夸特 |
| C8 衰亡与终章 | card_57–59, 61, 63–64, 66 | 钟声狂欢、罢耕、弑父、崩塌 |
| C9 贯穿氛围卡 | card_67–70 | 万寿菊/铁皮心/怀表/信（教学与特殊解锁） |

## 对照表

### 序章·下山（游戏第0章）

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F01 | L69–181 | 开场：母亲临终嘱托寻父；与赶驴人阿文迪奥同行下山，科马拉"热如火炭"；他也自称佩德罗之子 | C2 | card_70_carta | card_09_burro | present_camino_01/02, present_paramo_01, present_arriero_01, present_manos_01, present_retrato_01, present_climotes_01 |
| F02 | L187–221 | 傍晚进村：空街无人，裹披肩的妇人一闪而过 | C2 | card_16_rebozo | — | present_calle_01, present_plaza_01, present_rebozo_01 |
| F03 | L227–239 | 赶驴人告别独去；指往爱杜薇海斯家 | C2 | card_09_burro | — | present_cruce_01, present_casasvacias_01 |

### 第一章·空村投宿

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F04 | L245–293 | 爱杜薇海斯深夜开门；屋内家具堆积如山；"你母亲通知我你要来"（而母亲已死七天） | C2 | card_11_puerta | card_13_muebles | present_eduviges_sala_01/02, present_eduviges_puerta_01, present_eduviges_cara_01, present_eduviges_cuarto_01 |
| F05 | L299–329 | 【回忆】檐水滴进庭院水缸：少年佩德罗雨夜想苏萨娜 | C1 | card_04_gota | card_07_lavandera | memory_lluvia_patio_01, susana_lavadero_01 |
| F06 | L335–387 | 【回忆】替祖母剥玉米；蜂鸟声；"苏萨娜已随家人搬走" | C1 | card_03_maiz | card_02_colibri, card_06_abuela, card_05_molino | memory_maiz_01, memory_colibri_01, memory_pobreza_01, memory_molino_01 |
| F07 | L393–403 | 【回忆】夜雨再落，心随风筝断线远去 | C1 | card_01_papalote | — | memory_papalote_01 |
| F08 | L407–409 | 【回忆】母亲吹熄蜡烛、关门抽泣（家中丧讯之夜） | C1 | card_12_lampara | — | memory_luto_01 |
| F09 | L415–517 | 爱杜薇海斯自述婚夜替床始末："我差一点成了你的母亲" | C4 | card_27_cama | card_26_ramo | memory_boda_dolores_01, memory_cama_01, present_eduviges_joven_01 |
| F10 | L523–533 | 多罗莱斯携幼子离开科马拉那天；永别的预感 | C4 | card_31_carreta | — | memory_partida_01, memory_dolores_ventana_01, present_colima_01 |
| F11 | L539–601 | 米盖尔死讯之夜魂访爱杜薇海斯：翻墙赴约的路"找不到了" | C3 | card_20_anillo | — | present_ventana_miguel_01, memory_miguel_retrato_01 |
| F12 | L607–631 | 滴水声中：米盖尔的马科罗尼奥彻夜奔嘶寻主 | C3 | card_17_caballo | — | memory_camino_noche_01, woodcut_caballo_01 |
| F13 | L637–677 | 爱杜薇海斯谈天空与自赎；胡安母亲的眼睛 | C2 | card_10_retrato | — | present_cielo_01 |

### 第二章·回声（含神父插叙）

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F14 | L683–733 | 神父晚餐难安；侄女安娜哭诉米盖尔奸辱杀父之罪 | C3 | card_23_confesionario | — | memory_ana_01, memory_iglesia_01/02 |
| F15 | L739–779 | 米盖尔飞马夜驰康脱拉路；坠墙而死 | C3 | card_18_barda | — | memory_camino_noche_01, present_contla_01 |
| F16 | L785–787 | 流星满天，科马拉熄灯（空镜） | — | — | — | present_cielo_01 |
| F17 | L791–863 | 神父失眠自省；守灵夜收下金币，"愿他永受折磨"；教会向富人低头 | C3 | card_19_monedas | card_21_ataud, card_22_campana, card_24_doscuras | memory_velorio_01, memory_monedas_01, memory_funeral_miguel_01, memory_cura_cama_01, memory_dos_curas_01, memory_cura_noche_01 |
| F23 | L1053–1101 | 【现在】"这村庄处处是嗡嗡声"；达米亚娜领路，半路消失 | C2 | card_14_eco | — | present_eco_plaza_01, present_calle_damiana_01, present_barda_01 |
| F24 | L1107–1139 | 狗吠空街；赶车队幻影驶过无人叫卖 | C2 | card_62_perro | — | present_carretas_01, present_callejon_01, present_ventanas_01 |
| F25 | L1145–1181 | 午夜人声絮语；亡魂讨地、赶集、跳舞的残响 | C2 | card_65_sombra | — | present_sombras_baile_01, present_calle_noche_01 |
| F26 | L1187–1217 | "乔娜，跟我走"——无人处的私奔对话 | C2 | — | card_68_corazon | present_ventanas_01 |
| F27 | L1223–1227 | 喧闹与歌声（空镜短段） | — | — | — | present_eco_plaza_01 |

### 第三章·多尼斯兄妹与闷热

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F28 | L1231–1267 | 假嗓歌声引路；投宿多尼斯土屋；赤裸的姐弟 | C2 | card_15_llave | — | present_donis_01, present_donis_ext_01 |
| F29 | L1273–1469 | 多尼斯长段：乱伦之罪、主教拒赦、"罪的紫斑" | C2 | card_60_pueblovacio | — | memory_obispo_01, present_donis_01 |
| F30 | L1475–1547 | 屋顶破洞望画眉；姐姐说多尼斯走了 | C2 | card_38_estrella | — | present_donis_02 |
| F31 | L1553–1565 | 回到半截屋顶的房间；妇人熟睡 | — | — | — | present_donis_02 |
| F32 | L1571–1581 | 午夜热醒：身下的女人化成泥浆；八月的闷热 | — | — | — | present_calor_01 |

### 第四章·中点死亡与坟中（贯穿下半场的坟中插段并入此处）

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F33 | L1587–1703 | 【中点】"你想让我相信你是闷死的吗"：胡安死亡自述；与多罗脱阿同穴；她一生寻找从未存在的儿子 | C5 | card_33_tumba | card_34_almohada | woodcut_muerte_juan_01, present_tumba_01/02, present_bulto_01 |
| F34 | L1709–1715 | 坟中听雨；忆母亲说的雨后田野 | C5 | card_37_lluviatumba | — | present_tumba_02 |
| F35 | L1721–1769 | 深夜叫门与满村门响（剧本期需细读定位） | C5 | — | — | present_ventanas_01 |
| F45 | L2455–2471 | 坟中插段：多罗脱阿点明"层层叠叠的声音" | C5 | card_36_oido | — | present_tumba_01 |
| F48 | L2561–2575 | 坟中插段：听见苏萨娜在隔壁墓里翻身呓语 | C5 | card_35_raiz | — | present_tumba_01 |

### 第五章·半月庄崛起（佩德罗线）

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F18 | L869–889 | 阿尔德莱德的诉状与富尔戈尔的假证词 | C4 | card_30_papel | — | memory_papeles_01 |
| F19 | L893–957 | 富尔戈尔敲门讨债：少年佩德罗竟已当家；赖债定策（含卢卡斯之死回溯） | C4 | card_25_libro | card_08_balazo, card_32_medialuna | memory_despacho_01, memory_fulgor_01, woodcut_lucas_01, memory_medialuna_01 |
| F20 | L963–997 | "从哪学来这么多花招"：吞并多罗莱斯家产之计 | C4 | card_28_cerca | — | memory_cercas_01 |
| F21 | L1003–1033 | 提亲速成；多罗莱斯的喜悦 | C4 | card_26_ramo | — | memory_pedir_mano_01 |
| F22 | L1039–1047 | 客栈房内：阿尔德莱德被处死 | C4 | card_29_botas | — | memory_meson_01, woodcut_aldrete_01, present_soga_01 |

### 第六章·苏萨娜（蓝晒线核心）

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F36 | L1775–1979 | 神父多年后回忆那一夜：巴托洛梅父女来到；矿井；佩德罗的算计 | C6 | card_45_mina | — | susana_llegada_01, woodcut_mina_01, susana_bartolome_01 |
| F37 | L1985–2113 | 苏萨娜：睡在母亲死去的床上；猫；胡斯蒂娜 | C6 | card_41_gato | — | susana_recamara_01/02, susana_gato_01, memory_justina_01 |
| F38 | L2119–2139 | 佩德罗独白："我等你回来已等了三十年" | C6 | card_69_reloj | — | memory_pedro_ventana_01, memory_puerta_pedro_01 |
| F39 | L2145–2189 | "有些村庄带着不幸的滋味"；她是他唯一的光 | C6 | card_47_luna | — | memory_pedro_ventana_01 |
| F40 | L2195–2213 | 富尔戈尔与佩德罗谈她的疯癫 | C6 | card_43_espejo | — | susana_recamara_02 |
| F41 | L2219–2273 | 山谷细雨与农事；雨季的半月庄 | C6 | card_49_ojoagua | — | memory_medialuna_lluvia_01 |
| F42 | L2279–2351 | 午夜流水声；苏萨娜呓语忆海 | C6 | card_39_mar | — | susana_mar_01/02, susana_boca_01 |
| F43 | L2357–2391 | 连日风雨；幻觉加深（毛线画侵蚀演出位） | C6 | card_42_sabanas | — | susana_nierika_01 |
| F49 | L2581–2605 | 梦见弗洛伦西奥之死；海的身体记忆 | C6 | card_46_novio | card_40_gaviota | susana_florencio_01, susana_cuerpo_01 |
| F52 | L2833–2867 | 福斯塔太太夜望半月庄的灯："太太快死了" | C6 | card_48_velas | — | susana_viatico_01, present_ventanas_01 |
| F53 | L2873–2925 | "我嘴里塞满了泥土"：临终圣事，拒不认罪 | C6 | card_50_peine | — | susana_viatico_01, susana_boca_01 |
| F54 | L2931–2935 | 短讯：苏萨娜死了 | C6 | card_44_cruzmadre | — | susana_cuerpo_01 |

### 第七章·革命与钟声

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F44 | L2397–2449 | "结巴"报富尔戈尔被革命军打死；佩德罗令蒂尔夸特带人入伙 | C7 | card_51_fusil | — | woodcut_fulgor_01, memory_revolucion_01 |
| F46 | L2477–2527 | 革命军抵半月庄；佩德罗设宴周旋 | C7 | card_53_serpiente | — | memory_revolucion_01 |
| F47 | L2533–2555 | 蒂尔夸特领三百人入队 | C7 | card_55_sombrero | — | memory_tilcuate_01 |
| F50 | L2609–2641 | "干律师的好处"：赫拉尔多请辞 | C7 | — | — | memory_gerardo_01 |
| F51 | L2647–2827 | 赫拉尔多折返讨赏；蒂尔夸特战报流水；岁月流逝 | C7 | card_54_humo | — | memory_gerardo_01, present_balazos_01 |
| F55 | L2941–2963 | 12月8日晨钟长鸣三日；钟声引来集市狂欢；佩德罗："我将叉起双臂，科马拉将饿死" | C8 | card_57_campanas | card_58_papelpicado | memory_campanas_01, memory_feria_01/02, woodcut_calavera_feria_01 |
| F56 | L2969–2973 | 蒂尔夸特仍常来（短段） | C7 | card_52_bandera | — | memory_tilcuate_01 |
| F57 | L2977–2999 | 改投倭布雷冈；神父也上山打游击 | C7 | — | — | present_balazos_01 |

### 第八章·崩塌（终章）

| 碎片 | 原文 | 情节梗概 | 簇 | 主卡 | 副卡 | 场景资产 |
|---|---|---|---|---|---|---|
| F58 | L3005–3013 | 黎明前：佩德罗坐在椅上，叉着双臂，等待与回忆 | C8 | card_59_brazos | — | memory_brazos_01, memory_pedro_viejo_01 |
| F59 | L3019–3121 | 阿文迪奥：妻死无钱下葬、买酒、醉中持刀弑父；达米亚娜呼救 | C8 | card_61_cuchillo | card_56_gallo | present_abundio_camino_01, present_amanecer_01, woodcut_cuchillo_01, present_madrugada_01, present_cantina_01, present_velorio_pobre_01 |
| F60 | L3127–3153 | 终：佩德罗望着村庄"像一堆石头一样瘫塌" | C8 | card_64_piedras | card_63_silla, card_66_zopilote | woodcut_piedras_01, present_piedras_02, present_silla_01, present_exodo_01, present_milpa_seca_01, present_medialuna_01, present_cementerio_01, present_lamina_01, present_casaruinas_01 |

## 备注

- **无主卡碎片**（F16/F26/F27/F31/F32/F35/F50/F57）：空镜或过渡短段，不进拼图板，作为相邻碎片的演出延伸。
- **氛围卡** card_67_cempasuchil（万寿菊·引路教学卡）、card_68_corazon（铁皮心·笔记系统教学卡）、card_70_carta（母亲的信·开局即得的第一张卡）；card_67/68 不绑定单一碎片。
- F35 的精确剧情归属在剧本撰写期细读后回填（当前标注"待定"）。
- 副卡在拼图板上与主卡同槽位显示为一叠，翻看可见。


## 剧本期修订（M3，2026-08-08）

细读原文后修正若干碎片归属（以碎片 JSON 为准）：F12 实为「父亲被杀之夜」（主卡改 card_08_balazo）；F13 实为「葬礼与金币」（主卡 card_19_monedas+21）；F17 含爱杜薇海斯自尽揭示、阿尔德莱德绞刑房哀号与达米亚娜到来（card_29_botas 移此解锁）；胡安之死发生在 F32 末尾（非 F33 开头）。米盖尔簇拼图置于 F17，童年簇拼图置于 F08，鬼村簇拼图置于 F31。
