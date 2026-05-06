# AGENTS.md — 弹丸论破游戏项目

Godot 4.x (Forward+) GDScript 项目，弹丸论破风格学级裁判游戏框架。

## 项目文档

| 文档 | 用途 |
|------|------|
| `弹丸论破开发手册.md` | 完整架构设计、64 步开发计划、剧本指令 DSL |
| `更新记录.md` | 版本历史、已知问题、待办列表、开发日志 |
| `用户手册.md` | 玩家操作指南、按键速查 |
| `与弹丸论破的差异.md` | 与原版对比、完成度评估 |

## Godot 版本兼容

项目标注 `config/features=PackedStringArray("4.6", "Forward Plus")`（非真实版本号，仅元数据）。
实际在 Godot 4.x 运行。渲染器为 `forward_plus`。

### GDScript 严格类型警告

项目将类型推断警告视为错误。以下写法会**编译失败**：

```gdscript
# ❌ 不能：:= 推断 Variant
var x := dict.get("key", "default")
var f := FileAccess.open(path, FileAccess.READ)

# ✅ 必须：显式声明类型
var x: String = dict.get("key", "default")
var f: FileAccess = FileAccess.open(path, FileAccess.READ)
```

### Godot 4.x 禁止的语法

- `tween_method(func(t): ...)` — 匿名 lambda 在 tween 中不可用，必须用命名方法
- `tween_method(func_name.bind(a, b, c, d, e, f))` — 超过 3-4 个 bind 参数可能失败，改用成员变量
- `PanoramaSkyMaterial.sky_top_color` — 属性名跨版本不稳定，改用 `BG_COLOR`
- `Camera3D.current_enabled` — Godot 4 改为 `Camera3D.enabled`
- `class_name X extends Y` — 建议分两行写

## 关键架构

### Autoload 顺序（13 个，顺序很重要）

```
EventBus → SaveLoadManager → SceneManager → AudioManager
  → GameManager → CharacterManager → DebateManager → Logger
  → ScriptInterpreter → EvidenceManager
  → CharacterPortraitManager → MainGame → DebugConsole
```

MainGame 必须在最后（依赖其他所有 Autoload）。CharacterManager 必须在 ScriptInterpreter 之前（对话解析 speaker_label 需要）。

### 场景入口

- 主场景：`scenes/main.tscn`（空 Node，由 MainGame Autoload 动态构建 2D 世界）
- 裁判场：`scenes/3d/courtroom.tscn`（CourtroomScene 动态构建 3D 几何体）

**不要尝试编辑 .tscn 文件的 ext_resource/UID**，这是常见失败点。`scenes/main.tscn` 和 `courtroom.tscn` 只包含最小编排。

### 信号架构

所有模块通过 `EventBus`（`scripts/autoload/event_bus.gd`）通信。26 个信号覆盖对话/证据/HP/小游戏/场景/剧本/特效。

新增功能时先检查 EventBus 是否已有合适的信号，避免模块间直接耦合。

### 剧本系统

`ScriptInterpreter` 读取 `res://story/*.script.json`，逐条执行 27 个指令处理器。
剧本 JSON 格式参考 `story/test.script.json` 或 `story/courtroom_test.script.json`。

学级裁判指令（start_nonstop_debate 等）通过 `EventBus` 触发，由 `DebateManager` 创建对应小游戏 UI。

### 无休止议论 (Nonstop Debate)

最复杂的子系统，关键文件：
- `scripts/resources/debate_phrase.gd` — 单条发言数据（含 hotspots）
- `scripts/resources/nonstop_debate_config.gd` — 整场议论配置
- `scripts/minigames/floating_phrase.gd` — 飘动文字组件（句中词高亮）
- `scripts/minigames/nonstop_debate_ui.gd` — 议论主 UI（准星/言弹/发射/BREAK）

配置 JSON：`resources/debate_configs/debate_test_01.json`

`FloatingPhrase` 使用局部坐标系检测热点命中（`screen_point - global_position`），因为 CanvasLayer 中的 Control `global_position` 等同于屏幕坐标。

### 摄像机系统

`scripts/courtroom/courtroom_camera.gd` — 支持 4 种过渡预设 + 4 种锁定预设，在议论 JSON 中通过 `camera_transition`/`camera_lock` 配置。

运镜通过 `_tween_step(t: float)` 驱动，使用成员变量而非 bind 参数传递目标位置。

## 运行与测试

在 Godot 编辑器中按 **F5** 运行。进入后：
- 2D 场景：WASD 移动，E 对话，T 进入裁判场
- 裁判场：自动播放剧情，D=议论，R=反论，H=拼字，C=高潮，B=关闭小游戏，Esc=返回日常
- 调试控制台：`~` 键

Git 命令：`& "C:\env\Git\cmd\git.exe" <子命令>`（非标准安装路径）

## 已知陷阱

- `_courtroom_ref` 必须在 `NonStopDebateUI.start_debate()` 中显式赋值（`_find_courtroom()`），否则摄像机运镜静默失效
- 议论中 `_spawn_timer` 和 `_noise_timer` 必须在显示错误对话前 `stop()`，否则议论继续播放
- `DebateManager._active_debate_ui` 用于防止同时启动多个小游戏
- `SaveLoadManager` 和 `AudioManager` 代码完整但无 UI 触发/无音频资源
- 所有角色数据在 `resources/characters/characters.json`（17 个），通过 `CharacterManager` 加载
