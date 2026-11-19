# 宣传素材生成 / Media generation

这些脚本直接调用游戏的真实模型、材质和 UI，生成首发图文与演示片；没有独立重画宝石成品。
These scripts use the game models, materials and UI to generate launch cards and the demo.

- `capture_assets.gd`：10 种原石、7 颗加工后宝石、变石换光、收藏室与角色介绍截图，写入 `artifacts/media-assets`。
- `make_cards.gd`：六张 1080×1440 图文。
- `make_cover.gd`：1920×1080 视频封面。
- `make_video.gd`：72 秒实机演示，适用于 Godot Movie Maker，30 fps。
- `rough_portrait.gd`：以原游戏绘制逻辑单独捕获透明底原石。

用 Godot 4.7.2，在 `gem-atelier` 项目上下文中用 `--script` 传入脚本绝对路径。先捕获素材，再生成卡片与封面。视频录制前复制项目并把 viewport 与 window 尺寸设为 1920×1080，使用 `--write-movie`、`--fixed-fps 30`，避免改动正式游戏分辨率。视频需另用 FFmpeg 编码为 H.264/AAC；最终文件在 GitHub Release 的 MediaKit 中。
Use Godot 4.7.2 with the game project context and an absolute `--script` path. Capture assets before composing cards/cover. For Movie Maker, use an isolated project copy with viewport/window set to 1920×1080, `--write-movie` and `--fixed-fps 30`, then encode H.264/AAC with FFmpeg. Finished files are in the release MediaKit.

视频仅演示常见配方，部分工序加速；图文用的是实机导出的像素宝石。视频音乐署名见游戏 `audio/CREDITS.md`；截取、音量调整和混音已在发布文案标明。
The video accelerates some processing. Cards use exported in-game pixel gems. Music attribution is in the game audio credits; the posting copy discloses excerpting, volume adjustment and mixing.
