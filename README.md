# JoyHarness

将 Nintendo Switch Joy-Con 手柄通过蓝牙映射为键盘快捷键。支持单左手柄、单右手柄、双手柄三种连接模式，自动检测并热切换配置。

> 本 Fork 在原项目 [VaderCheng/JoyHarness](https://github.com/VaderCheng/JoyHarness)（仅 Windows）基础上增加了完整的 macOS 支持。

## 界面预览

| Windows | macOS |
|---------|-------|
| ![Windows](assets/screenshot.png) | ![macOS](assets/screenshot-mac.png) |

## 功能特性

- **多手柄模式** — 自动检测右手柄 / 左手柄 / 双手柄，切换对应键位配置
- **热插拔** — 断开重连自动恢复
- **丰富的按键映射** — tap、hold、auto（短按/长按自适应）、combination（组合键）、sequence（序列键）、app_switcher、macro（宏）、window_switch、exec（Shell 命令）
- **摇杆映射** — 4/8 方向，可配死区
- **窗口切换** — 快速切换指定应用窗口
- **GUI 设置** — 可视化编辑键位映射
- **电量显示** — HID 读取 Joy-Con 电量
- **保活防休眠** — 周期性零强度震动

## 快速开始

### 环境要求

- **Windows 11** 或 **macOS 13+**（实测 macOS 15.7，Apple Silicon M4）
- Python 3.10+
- Joy-Con 已通过蓝牙配对

### 安装

```bash
pip install -r requirements.txt
pip install -e .
```

依赖已按平台自动分流：Windows 安装 `keyboard`，macOS 安装 `pynput` + PyObjC。

### 蓝牙配对

1. 打开系统蓝牙设置
2. 按住 Joy-Con 滑轨上的小配对按钮 3 秒（指示灯快速闪烁）
3. 在蓝牙列表中选择 Joy-Con

### 运行

```bash
joyharness
```

也兼容旧入口：

```bash
python -m src
```

如果当前 `python` 缺少 `tkinter` / `_tkinter`，但仓库内的 `.venv` 可用，`python -m src` 会自动使用 `./.venv/bin/python`（Windows 为 `./.venv/Scripts/python.exe`）重新启动，避免因系统 Python 缺少 Tk 而直接失败。标准入口 `joyharness` 建议安装在 `.venv` 里使用。

macOS 可双击 `start.command`，Windows 可双击 `start.vbs`。

macOS 首次运行需在 **系统设置 → 隐私与安全性** 中授予 **辅助功能** 和 **输入监控** 权限。

### macOS 开机自启 / 崩溃自启

使用 LaunchAgent 跑在当前用户会话里。它会在登录时自动启动 JoyHarness；进程退出或崩溃后，launchd 会自动拉起。

如果开机时 Joy-Con 还没连上，JoyHarness 会保持运行并等待手柄连接，不会因为未检测到 Joy-Con 而退出重启。

安装并立即启动：

```bash
scripts/install-launch-agent.sh
```

查看状态和日志路径：

```bash
scripts/status-launch-agent.sh
```

卸载：

```bash
scripts/uninstall-launch-agent.sh
```

安装位置和日志：

```text
~/Library/LaunchAgents/com.joyharness.agent.plist
~/Library/Logs/JoyHarness/stdout.log
~/Library/Logs/JoyHarness/stderr.log
```

### 常用命令行参数

```
joyharness --discover        # 校准：显示按钮/轴的原始索引值
joyharness --config my.json  # 使用自定义配置文件
joyharness --list-controls   # 列出当前映射
joyharness --verbose         # 调试日志
```

## 配置

配置文件位于 `config/` 目录，JSON 格式：

- `user.json` — 主配置文件（优先加载）
- `user-macos.json` — macOS 预设
- `user-windows.json` — Windows 预设
- `default.json` — 内置默认

程序启动时自动根据平台选择配置：优先 `user.json`，其次 `user-{platform}.json`。

正常运行时会热加载当前配置文件。修改并保存 `config/user.json` 后，约 1 秒内自动生效，无需重启 `python -m src`。热加载会更新：

- 按键和摇杆映射
- `selected_apps` / `known_apps` 窗口切换目标
- `deadzone`、`poll_interval`、`stick_mode`、`stick_activation_button`
- `keep_alive_enabled`

如果 JSON 暂时写坏或键名无效，程序会保留旧配置并在日志里提示；修好并再次保存后会继续加载。

### 连接模式

| 模式 | 可用按钮 |
|------|----------|
| `single_right` 右手柄 | A/B/X/Y/R/ZR/Plus/Home/RStick/SL/SR |
| `single_left` 左手柄 | A/B/X/Y/L/ZL/Minus/Capture/LStick/SL/SR |
| `dual` 双手柄 | 全部按钮 |

### 动作类型

| 动作 | 说明 |
|------|------|
| **tap** | 点击后立即松开 |
| **hold** | 按下保持，松开释放（修饰键用） |
| **auto** | 短按 = tap，长按 = hold。加 `repeat` 字段可连续重击 |
| **combination** | 同时按多个键（如 Cmd+S） |
| **sequence** | 按住修饰键 + 点击其他键（如 Alt+Tab） |
| **app_switcher** | 原生 macOS Cmd+Tab 应用切换器 |
| **window_switch** | 短按切下一个窗口，长按弹出选择器 |
| **macro** | 预定义按键序列，可按前台窗口过滤 |
| **exec** | 执行 Shell 命令（如 `open -a "Mission Control"`） |

### macOS 专用配置示例

```json
{
  "ZR": { "action": "hold", "key": "alt" },
  "Plus": { "action": "hold", "key": "cmd_r" },
  "R": { "action": "app_switcher" },
  "SR": { "action": "combination", "keys": ["shift_l", "alt_l", "cmd_l"] },
  "Y": { "action": "combination", "keys": ["cmd", "`"] },
  "Home": { "action": "combination", "keys": ["cmd", "space"] },
  "B": { "action": "auto", "key": "backspace", "repeat": 100 }
}
```

当前 `config/user.json` 的右手柄预设：

| Joy-Con 按键 | 动作 |
|--------------|------|
| `R` | 原生 Cmd+Tab 应用切换器 |
| `SR` | 触发 Typeless 监听快捷键：Left Shift + Left Option + Left Cmd |
| `ZR` | 按住左 Option / Alt，配合摇杆左右可按词移动光标 |
| `SL` + 摇杆 | 启用摇杆方向键，避免误触 |
| `Home` | Cmd+Space，打开 Spotlight |
| `Y` | Cmd+`，当前 App 内切换窗口 |
| `B` | Backspace，长按连删 |
| `A` | Enter |
| `X` | Escape |
| `RStick` | Tab |

### 多应用切换

`R` 使用 `app_switcher` 动作，行为等同键盘上的 Cmd+Tab：

- 按住 `R`：按住 Cmd 并点一次 Tab，唤起 macOS 原生应用切换器
- 按住 `R` 时摇杆右/下：Tab，选下一个 App
- 按住 `R` 时摇杆左/上：Shift+Tab，选上一个 App
- 按住摇杆方向不放：每 `switch_scroll_interval` 毫秒连续移动
- 松开 `R`：释放 Cmd，切到当前选中的 App

这个模式使用系统原生 App Switcher，会显示所有正在运行的 App，不受 `selected_apps` 限制。

当前切换速度：

```json
{
  "deadzone": 0.35,
  "switch_scroll_interval": 160,
  "stick_directions": {
    "up": { "repeat": 180 },
    "down": { "repeat": 180 },
    "left": { "repeat": 180 },
    "right": { "repeat": 180 }
  }
}
```

`deadzone` 越大，越不容易被轻微拨动触发。`switch_scroll_interval` 和 `repeat` 越大，连续移动越慢。建议范围：`deadzone` 用 `0.30` 到 `0.45`，`switch_scroll_interval` / `repeat` 用 `140` 到 `220`。

`selected_apps` 只用于旧的 `window_switch` 动作。当前保留预设：

```json
["Codex", "Telegram", "Slack", "ghostty"]
```

要增删切换目标，修改 `config/user.json`：

```json
{
  "known_apps": {
    "Codex": "Codex",
    "Telegram": "Telegram",
    "Slack": "Slack",
    "Ghostty": "ghostty",
    "Typeless": "Typeless"
  },
  "selected_apps": ["Codex", "Telegram", "Slack", "ghostty"]
}
```

`known_apps` 的值必须是 macOS 看到的应用进程名；本机 Ghostty 进程名是小写 `ghostty`。不确定时先运行 `python -m src --verbose`，或用 GUI 设置面板添加/勾选应用。`window_switch` 主要切应用窗口；跨 Space / 全屏窗口受 macOS 限制。

### 摇杆防误触

`stick_activation_button` 控制摇杆门控。当前设置为：

```json
{
  "stick_activation_button": "SL"
}
```

效果：只有按住 `SL` 时，摇杆方向才会触发键盘方向键。单独碰到摇杆不会输入。要恢复一直启用，改成 `null`。

例外：按住 `R` 做原生 Cmd+Tab 应用切换时，摇杆会临时用于选择 App，不需要同时按 `SL`。

> macOS 上部分系统快捷键（如 F3 → Mission Control）只响应硬件 HID 事件，不响应 pynput 合成的按键。这类场景请用 `exec` 动作。

## macOS 注意事项

- **权限**：需要「辅助功能」和「输入监控」权限
- **权限对象**：如果从终端运行 `python -m src`，需要给运行它的终端 App（Terminal / Ghostty / iTerm）授权；必要时也给 Python 或 `.venv/bin/python` 授权
- **LaunchAgent 权限对象**：如果使用开机自启，需要给仓库内的 `.venv/bin/python` 授权「辅助功能」和「输入监控」
- **进程名大小写敏感**：中文系统下微信进程名是 `微信`，不是 `WeChat`
- **全屏窗口**：`window_switch` 只能看到当前 Space 的窗口
- **SL/SR 侧键**：在 macOS 上 SDL2 检测不稳定，建议映射为其他功能

### macOS 排查

如果 `--discover` 能看到按钮，但按键没有输入到系统：

1. 在「系统设置 → 隐私与安全性 → 辅助功能」授权运行 JoyHarness 的终端 App。
2. 在「系统设置 → 隐私与安全性 → 输入监控」授权同一个终端 App。
3. 完全退出终端 App，重新打开。
4. 用下面命令测试键盘合成是否生效：

```bash
python - <<'PY'
import time
from pynput.keyboard import Controller
print("Focus a text field within 3 seconds. Will type: joytest")
time.sleep(3)
Controller().type("joytest")
print("Done")
PY
```

如果文本框出现 `joytest`，键盘输出权限正常。再运行：

```bash
python -m src --verbose
```

按 Joy-Con 按键，日志中应能看到对应的 `tap` / `hold` / `combination` 动作。

## 项目结构

```
src/
├── main.py              # CLI 入口 + 线程编排
├── config_loader.py     # 配置加载/校验/保存（平台自动选择）
├── constants.py         # 硬件常量、默认映射
├── joycon_reader.py     # pygame 手柄轮询、热插拔重连
├── key_mapper.py        # 事件翻译引擎（核心）
├── keyboard_output.py   # 键盘模拟（Windows=keyboard / macOS=pynput）
├── window_switcher.py   # 窗口枚举/切换（Win32 / Quartz+AppleScript）
├── gui.py               # 主窗口
├── settings_window.py   # 设置面板
├── switcher_overlay.py  # 窗口切换叠加层
├── tray_icon.py         # 系统托盘图标（仅 Windows）
├── battery_reader.py    # HID 电量读取
├── keep_alive.py        # 保活防休眠
└── platform/            # 平台检测 + 权限检查
```

## 本 Fork 变更

基于 [@VaderCheng](https://github.com/VaderCheng/JoyHarness) 的 Windows 原版：

- **完整 macOS 支持** — 键盘模拟、窗口管理、HID 电量、保活、GUI 全部适配
- **`exec` 动作** — 绑定 Shell 命令到按键（Mission Control、Launchpad 等）
- **`auto` 连发** — `repeat` 字段实现软件层面的按键连发
- **平台配置自动选择** — 根据操作系统加载对应的配置文件
- **pygame 选择性初始化** — 减少 SDL2 对 macOS 窗口管理的干扰
- **窗口切换性能优化** — PyObjC + Quartz 替代 AppleScript（延迟从 ~500ms 降至 ~20ms）
- **Bug 修复** — 8 向摇杆判定、窗口切换状态机、GUI 配置保存

## 许可证

[MIT](LICENSE)
