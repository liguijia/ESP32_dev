# ESP32 开发环境（Docker / Dev Container / ESP-IDF）

这是一个面向 **ESP-IDF** 的 ESP32 容器化开发环境，目标是让你在进入 VS Code Dev Container 后，尽快达到：

- 能直接编译 ESP32 工程
- 能基于模板快速创建新工程
- 能在 Docker / WSL / `usbipd attach` 场景下自动发现串口
- 能通过统一的 `Makefile` 工作流完成 build / flash / monitor / doctor

如果你的宿主机、WSL、Dev Container、USB 设备透传链路已经正常，那么当前工作区已经基本具备 **开箱即用** 的 ESP32 开发能力。

---

## 1. 当前工作区现状结论

基于当前仓库实际文件和容器环境检查，可以确认：

- 已配置 **VS Code Dev Container**
- 已内置 **ESP-IDF v5.4.2** 工具链
- 已有可编译示例工程：`hello_world/`
- 已有可复用模板工程：`user_template/`
- 已有新工程创建脚本：`script/create_user_project.sh`
- 已支持 Docker / WSL / `usbipd attach` 场景下的 **自动串口发现**
- 已有项目级 `.vscode` 调试配置生成能力
- 已有配套文档覆盖：工作流、串口下载、模板使用、脚本使用

### 结论

**是的，它现在已经基本是一个可开箱即用的 ESP32 开发环境。**

但这里的“开箱即用”有一个现实前提：

- 容器需要成功启动
- 如果你要连真实开发板，需要先完成 `usbipd attach` 或等价的设备透传

也就是说：

- **软件环境：已经基本开箱即用**
- **硬件连接：仍需要你把板子接入当前容器链路**

---

## 2. 当前能力概览

### 2.1 容器与工具链

当前环境具备：

- Dev Container 配置：`.devcontainer/devcontainer.json`
- 容器初始化脚本：`.devcontainer/post-create.sh`
- ESP-IDF 版本：`v5.4.2`
- 工作区根目录：`/workspaces/ESP32_dev`

容器启动后，你可以直接执行：

```bash
idf.py --version
```

当前实测结果为：

```text
ESP-IDF v5.4.2
```

### 2.2 示例工程

当前工作区包含：

- `hello_world/`：标准示例工程
- `user_template/`：已增强的用户模板工程

这两个工程当前都已存在 `build/` 目录，说明它们在当前环境中已经经过构建验证。

### 2.3 模板工程能力

`user_template/` 当前已经具备：

- 统一的 `Makefile` 工作流
- 自动串口发现脚本：`tools/detect_serial_port.sh`
- `make doctor` 自检能力
- `make port` 串口探测能力
- `make build / flash / monitor / run` 常用命令

### 2.4 新工程创建能力

当前脚本：

```text
script/create_user_project.sh
```

支持：

- 指定目标芯片：`--target`
- 指定串口策略：`--port auto|<path>`
- 自动生成项目级 `.vscode` 配置
- 自动执行 `idf.py set-target` 与 `idf.py reconfigure`
- 复制模板里的自动串口发现能力

---

## 3. 当前目录结构

```text
ESP32_dev/
├── .devcontainer/                    # Dev Container 配置
│   ├── Dockerfile
│   ├── devcontainer.json
│   └── post-create.sh
├── .vscode/                          # 工作区级 VS Code 配置
├── doc/                              # 文档
│   ├── ESP32_C3_USBIPD_串口下载.md
│   ├── ESP32_工作流与SDK导航.md
│   ├── ESP32_开发与调试指南.md
│   └── 新工程创建脚本使用说明.md
├── hello_world/                      # 示例工程
├── script/
│   └── create_user_project.sh        # 新工程创建脚本
├── user_template/                    # 用户模板工程
│   ├── main/
│   ├── tools/
│   │   └── detect_serial_port.sh     # 自动串口发现脚本
│   ├── CMakeLists.txt
│   ├── Makefile
│   ├── README.md
│   ├── sdkconfig
│   └── sdkconfig.defaults
└── ESP32_dev.code-workspace          # 多根工作区入口
```

---

## 4. 推荐使用方式

### 4.1 进入开发环境

推荐使用 **VS Code + Dev Containers**：

1. 用 VS Code 打开仓库根目录
2. 执行 `Reopen in Container`
3. 等待容器初始化完成

当前 `.devcontainer/devcontainer.json` 已完成这些关键配置：

- 工作区挂载
- `/dev` 挂载到容器内 `/host-dev`
- `--privileged`
- 自动执行 `.devcontainer/post-create.sh`
- 安装 `espressif.esp-idf-extension`

### 4.2 验证工具链

进入容器后，先执行：

```bash
idf.py --version
```

如果输出 ESP-IDF 版本，说明软件环境已经就绪。

---

## 5. 串口与真实开发板接入

如果你只是做代码阅读、编译、静态检查，那么进入容器后通常就可以直接开始。

如果你要 **烧录真实开发板 / 查看串口日志**，还需要完成硬件接入。

### 5.1 当前场景

当前仓库默认面向：

- Windows 宿主机
- WSL
- VS Code Dev Container
- 通过 `usbipd attach` 把设备挂进 WSL

### 5.2 推荐流程

在 Windows PowerShell 中：

```powershell
usbipd attach --wsl --busid <busid> --auto-attach
```

然后回到 Dev Container 内验证串口。

### 5.3 当前自动串口发现策略

模板与新工程都默认按如下顺序自动寻找串口：

1. `/host-dev/serial/by-id/*`
2. `/dev/serial/by-id/*`
3. `/host-dev/ttyACM*`
4. `/host-dev/ttyUSB*`
5. `/dev/ttyACM*`
6. `/dev/ttyUSB*`

这意味着：

- 优先使用稳定的 `by-id` 路径
- 如果只有一个可用设备，会自动选中
- 如果检测到多个设备，不会乱猜，而是要求你手动指定 `PORT`

---

## 6. 快速开始

### 6.1 编译示例工程

```bash
cd /workspaces/ESP32_dev/hello_world
idf.py build
```

### 6.2 使用模板工程直接开发

```bash
cd /workspaces/ESP32_dev/user_template
make port
make doctor
make build
```

如果串口链路已经准备好，可以继续：

```bash
make flash-monitor
```

或者：

```bash
make run
```

### 6.3 基于模板创建新工程

```bash
cd /workspaces/ESP32_dev
./script/create_user_project.sh my_app
```

指定目标芯片：

```bash
./script/create_user_project.sh --target esp32s3 my_s3_app
```

指定串口策略：

```bash
./script/create_user_project.sh --port auto my_app
./script/create_user_project.sh --port /host-dev/serial/by-id/your-device my_app
```

创建完成后：

```bash
cd /workspaces/ESP32_dev/my_app
make port
make build
```

---

## 7. 模板工程常用命令

在 `user_template/` 或新生成工程目录中，可使用：

```bash
make port           # 查看自动探测到的串口与候选设备
make doctor         # 检查串口、工具链、构建产物、flash 参数
make build          # 编译
make reconfigure    # 重新配置工程
make flash          # 烧录
make monitor        # 打开串口日志
make flash-monitor  # 烧录并打开日志
make run            # build + flash + monitor
make erase-app      # 擦除应用区
make erase-flash    # 整片擦除
```

如果自动发现失败或存在多个设备，可以手工覆盖：

```bash
make run PORT=/host-dev/serial/by-id/your-device
```

---

## 8. 是否真的“开箱即用”？

### 可以明确回答“是”的部分

下面这些部分，当前仓库已经做到了接近开箱即用：

1. **ESP-IDF 工具链**：容器内可直接使用
2. **示例工程编译**：`hello_world/` 可直接构建
3. **模板工程**：`user_template/` 可直接作为起点
4. **新工程创建**：脚本可直接生成新项目
5. **串口自动发现**：已适配 Docker / WSL / `usbipd attach`
6. **VS Code 调试配置生成**：新工程创建时自动补齐
7. **文档**：已有工作流、串口、模板、脚本说明

### 仍然需要你具备的前提条件

下面这些属于“环境外部条件”，仓库无法完全替你完成：

1. **Docker / Dev Container 要能正常启动**
2. **真实开发板要物理接入主机**
3. **如果走 Windows + WSL，需要先执行 `usbipd attach`**
4. **如果有多个串口设备，你需要明确要操作哪一个**

### 最终判断

如果你问的是：

> 这个工作区现在是不是已经能让我进入容器后，直接开始 ESP32 开发，而不是再从零搭环境？

答案是：

**是，已经可以。**

如果你问的是：

> 我不接板子、不做任何 `usbipd attach`，也能直接烧录真实设备吗？

答案是：

**不能。** 因为那是硬件接入问题，不是仓库内部软件配置问题。

---

## 9. 当前最推荐的实际操作顺序

### 只验证开发环境

```bash
cd /workspaces/ESP32_dev/hello_world
idf.py build
```

### 验证模板工程工作流

```bash
cd /workspaces/ESP32_dev/user_template
make port
make doctor
make build
```

### 验证真实板子烧录与日志

```bash
cd /workspaces/ESP32_dev/user_template
make run
```

如果有多个串口，则：

```bash
make run PORT=/host-dev/serial/by-id/your-device
```

### 创建自己的新工程

```bash
cd /workspaces/ESP32_dev
./script/create_user_project.sh --target esp32c3 --port auto my_project
cd my_project
make port
make build
```

---

## 10. 相关文档

- `doc/ESP32_开发与调试指南.md`
- `doc/ESP32_工作流与SDK导航.md`
- `doc/ESP32_C3_USBIPD_串口下载.md`
- `doc/新工程创建脚本使用说明.md`

---

## 11. 备注

当前根目录 README 以“当前仓库真实能力”为准，重点强调：

- 当前是 **ESP-IDF** 工作流，不是 PlatformIO
- 当前推荐从 `user_template/` 和 `script/create_user_project.sh` 开始
- 当前默认串口策略是 **自动发现优先，手工覆盖兜底**

如果后续你还要继续增强这个环境，下一步最值得做的事情通常是：

1. 增加更稳定的 VS Code / OpenOCD / JTAG 调试说明
2. 统一修正文档中部分历史遗留表述
3. 增加多板并行开发时的串口选择规范
