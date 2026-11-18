# 石间 · Gem Atelier

一间安静的小宝石工坊。挑一块原石，切出自己的形状，抛光后把它放到灯下转一转。
A quiet gemstone workshop: choose a rough stone, cut and polish it, then turn it under the light.

**[下载 Windows 游戏 / Download Windows game](https://github.com/TimrayZ/gem-atelier/releases/latest)**

![当前源码版本：日光下的椭圆钻石 / Current source build: oval diamond in daylight](docs/images/showcase.png)

## 下载后怎么玩 / Play

1. 在 Releases 下载 **GemAtelier-v0.9.0-Windows-x64.zip**，完整解压到一个文件夹。不要选择 GitHub 自动生成的 Source code。
2. 双击 **GemAtelier.exe**。无需安装 Godot，无需联网。
3. 左侧选宝石，右侧选琢型。按 **F8** 自动加工，快速进入成品展台；手动操作则跟着右下角按钮推进。
4. 成品拖动旋转、滚轮缩放，按 **1 / 2 / 3** 比较日光、白炽灯和中性光。喜欢就收入收藏室。
5. 点击顶部“收藏室”，作品会摆在哑光绒布上。点一颗重新旋转、换光查看，再返回继续加工。

Download the Windows ZIP from Releases, extract the entire archive, and run **GemAtelier.exe**. No Godot installation or network connection is needed. Choose a material and cut, then press **F8** for automatic processing. Drag the gem to rotate, scroll to zoom, and press **1 / 2 / 3** for lighting. Save favorites to the velvet-lined collection room and click them to inspect them again.

目标平台：Windows 10/11 64 位、支持 OpenGL 3.3 的显卡。光学展台较吃 GPU，卡顿时可点击“光路”切到 6 次或切换刻面对照。目前尚未在其他电脑的各种显卡上验证。
Targets 64-bit Windows 10/11 with OpenGL 3.3. The optical viewer is GPU intensive: choose six bounces or the flat facet view if needed. Hardware compatibility beyond the development machine remains unverified.

## 工坊里有什么 / Features

- 五种材料：亚历山大变石、紫水晶、蓝宝石、钻石、透明正长石；各有原生晶形与磨圆原料示例。
- 五种琢型：八角、椭圆、八重对称、长方阶梯、圆形明亮（心箭试验）。
- 逐面移除真实体积：切歪会留下不同形状，崩角会留下缺角，可以继续完成有瑕疵的作品。
- 每面一次抛光；F8 自动完成后续工序；滴水冷却、轻／重压和简化晶向选择。
- 光谱折射、表面反射、内部全反射、色散、路径吸收及可选内含物；三种照明对照。
- 左侧“百科”：组成、原料与成品形状、硬度、韧性、解理、折射率、拟合吸收谱。
- 独立绒布收藏室：使用已保存真实几何渲染缩略图，可重新查看作品；浏览不会覆盖正在加工的石头。
- 小龙珑珑平时安静，点击角色或手记才会介绍；她也正和你一起学习。

Five materials and five cuts; progressive solid cutting with permanent mistakes and chips; one polishing pass per face; fast processing; cooling, pressure and simplified crystal orientation; spectral optics; a mineral encyclopedia; a velvet collection room with actual saved-shape thumbnails and reopening; and an optional quiet dragon guide.

![收藏室 / Collection room](docs/images/collection.png)

| 操作 / Control | 功能 / Action |
| --- | --- |
| F8 | 开始／停止快速加工 / Start or stop fast processing |
| 空格或按住加工按钮 / Space or hold work | 加工当前面 / Work on current face |
| ← / → | 切换加工面 / Select facet |
| 拖动 / Drag | 旋转观察 / Rotate |
| 滚轮 / Wheel | 缩放 / Zoom |
| 1 / 2 / 3 | 切换照明 / Change illuminant |
| H / J | 冠部／亭部正视 / Crown or pavilion view |
| Esc | 关闭百科、手记或收藏室 / Close encyclopedia, notes or collection |

## 存档 / Saves

在展台点击“收藏真实切工”才会保存作品。存档和偏好位于 `%APPDATA%/Godot/app_userdata/石间 · Gem Atelier/`；更新游戏可以保留。正在加工的石头不会自动保存。收藏室查看旧作品后，右下角可返回收藏室，再回到原来的工坊进度。
Only collected finished pieces are saved. Saves and preferences live in the Godot user-data directory above and survive replacing the game folder. Work in progress is not autosaved. Inspecting a collected gem preserves the current workshop session.

## 模拟范围 / Simulation limits

这是自写的凸多面体光线追踪原型：实际切后边界、Snell 折射、Fresnel 能量分配、全反射、20 波段色散与 Beer–Lambert 吸收。吸收谱为拟合，照明为黑体近似；未完整模拟偏振、双折射、多色性、完整间接照明和焦散。反射次数有限，仍可能有细小混叠或转动闪烁。减少反射次数不能保证消除摩尔纹。圆形明亮配方尚未验证达到八心八箭。
This custom convex-solid ray tracer uses actual cut boundaries, Snell refraction, Fresnel splitting, total internal reflection, 20 spectral bands and Beer–Lambert absorption. Absorption is fitted and illumination approximates blackbody spectra. Full polarization, birefringence, pleochroism, indirect illumination and caustics are not implemented. Fine aliasing or shimmer can remain; fewer bounces do not guarantee its removal. The round-brilliant recipe is not a verified hearts-and-arrows cut.

缺角会实际截去体积，尚不能生成凹入的贝壳状破口。晶向风险、评分和温度阈值是游戏设计，不是实际加工指南。硬度不等于韧性；玻璃也不能一概认定无法切刻面。
Chips remove actual volume through convex truncation, rather than modeling concave conchoidal fractures. Risk, score and heat thresholds are gameplay values, not manufacturing guidance. Hardness differs from toughness; glass can be faceted under suitable conditions.

## 从源码运行 / Source

用 **Godot 4.7.2 Standard** 打开 `gem-atelier/project.godot`，等待导入后按 F5。Compatibility 渲染器，无需 .NET。Windows 导出需同版本官方模板，预设见 `gem-atelier/export_presets.cfg`。
Open `gem-atelier/project.godot` in Godot 4.7.2 Standard, allow imports, then press F5. Compatibility rendering requires no .NET. Windows export needs matching official templates; see the included export preset.

模型测试：`godot --headless --path gem-atelier --script res://tests/test_workshop.gd`。另有 `test_shapes.gd`、`test_damage.gd` 和图形流程测试 `test_collection.gd`；图形测试需要 OpenGL 环境。
Run the command above for model tests; additional scripts cover all material/cut combinations, damage and collection browsing. Graphical tests require OpenGL.

## 下一版故事方案 / Story proposal

[Grace Pandora 坦格利安与工坊故事草案](docs/角色与故事方案.md)：昵称“潘潘”，24 岁主角与外出旅行的爷爷，以及不阻塞操作的开场自我介绍。本次仅提交方案，现有游戏剧情与 v0.9.0 下载版保持原样。
[Character and story proposal](docs/角色与故事方案.md): Grace Pandora Targaryen, nicknamed Panpan; a 24-year-old protagonist; a grandfather away on a journey; and an unobtrusive opening introduction. This is a proposal only; the current game narrative and v0.9.0 download remain unchanged.

## 署名与许可 / Credits and licenses

- **Carefree — Kevin MacLeod (incompetech.com)**，音乐适用 [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/)，录音未修改、降低播放音量。[原始来源 / Original source](https://remote.incompetech.com/music/royalty-free/index.html?Search=Search&isrc=USUAN1400037) · [完整音频署名 / Audio credits](gem-atelier/audio/CREDITS.md).
- [Godot Engine](https://godotengine.org/license/)，MIT 及相关第三方许可；Windows 下载附带运行时许可文本。MIT and third-party runtime notices accompany the Windows download.
- GPT 助手立绘按用户提供的角色参考由 AI 生成。GPT assistant portrait generated with AI from a user-provided character reference.
- 矿物数据 / Mineral facts: [Handbook of Mineralogy](https://www.handbookofmineralogy.org/)、[GIA](https://www.gia.edu/)。[本版研究与验证 / Research and validation](docs/发布说明0.9.md).

原始代码采用 [MIT](LICENSE)。音乐与涉及第三方角色参考的图像不在代码许可授权范围内。
Original code is [MIT licensed](LICENSE). Music and third-party rights associated with the character-reference artwork are excluded from that source-code license.
