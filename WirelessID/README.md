# WirelessID

这是一个面向 **ESP32-C3 + ESP-IDF** 的可复用模板工程，目标是让你在复制后能快速开始，而不是每次都从空工程重新整理串口、构建和基础日志。

## 适合拿它做什么

- 新建一个最小可运行的 ESP32-C3 应用
- 作为后续 GPIO / Wi-Fi / BLE / 传感器项目的起点
- 在当前 Docker / WSL / Dev Container 环境里快速验证下载链路
- 给团队成员提供统一的工程起步模板

## 当前模板特点

- 默认匹配 **4MB flash**
- 默认优先自动发现稳定的 `by-id` 串口路径
- 上电后持续输出心跳日志，便于确认系统仍在运行
- `Makefile` 封装常用构建、烧录、复位、诊断动作
- 应用基础配置集中在 `main/include/WirelessID_config.h`

## 目录结构

```text
WirelessID/
├── CMakeLists.txt
├── Makefile
├── README.md
├── sdkconfig
├── sdkconfig.defaults
├── tools/
│   └── detect_serial_port.sh
└── main/
    ├── CMakeLists.txt
    ├── WirelessID.c
    └── include/
        └── WirelessID_config.h
```

## 最常用命令

在工程目录执行：

```bash
cd /workspaces/ESP32_dev/WirelessID
```

### 1. 环境自检

```bash
make doctor
```

### 2. 编译

```bash
make build
```

### 3. 烧录并看日志

```bash
make flash-monitor
```

### 4. 仅查看串口日志

```bash
make log
```

退出串口日志时，优先使用：

```text
Ctrl + ]
```

说明：`idf.py monitor` 默认不是通过 `Ctrl + C` 退出，所以如果你发现日志一直刷、`Ctrl + C` 没反应，这是正常现象。

### 5. 仅擦除应用区

```bash
make erase-app
```

## 新项目复用建议流程

### 第一步：复制模板目录

把 `WirelessID` 复制成你的新工程名，例如：

```bash
cp -r /workspaces/ESP32_dev/WirelessID /workspaces/ESP32_dev/my_project
```

### 第二步：改项目名

至少改这两个位置：

- `CMakeLists.txt` 中的 `project(...)`
- `main/include/WirelessID_config.h` 里的 `WIRELESSID_APP_NAME` 和 `WIRELESSID_LOG_TAG`

### 第三步：替换应用逻辑

先从：

```text
main/WirelessID.c
```

开始，把当前心跳逻辑换成你的实际业务逻辑。建议保留启动日志，这样排障最快。

### 第四步：重新配置并构建

```bash
make reconfigure
make build
```

## 建议优先修改的配置

文件：

```text
main/include/WirelessID_config.h
```

你通常会最先改这几个值：

- `WIRELESSID_APP_NAME`
- `WIRELESSID_LOG_TAG`
- `WIRELESSID_STARTUP_BANNER`
- `WIRELESSID_HEARTBEAT_INTERVAL_MS`

## 工程化命令说明

- `make flash`：烧录完整镜像
- `make flash-monitor`：烧录后直接打开日志
- `make log`：日志快捷入口
- `make reboot`：通过串口复位芯片
- `make erase-app`：擦除 app 区，不影响 bootloader / partition table
- `make erase-flash`：整片 flash 擦除
- `make doctor`：检查串口、工具链、构建产物、flash 参数

## 自动串口发现

模板默认会优先按下面顺序自动寻找串口：

1. `/host-dev/serial/by-id/*`
2. `/dev/serial/by-id/*`
3. `/host-dev/ttyACM*`
4. `/host-dev/ttyUSB*`
5. `/dev/ttyACM*`
6. `/dev/ttyUSB*`

这比较适合当前的 Docker / Dev Container + `usbipd attach` 场景。

你可以先查看自动检测结果：

```bash
make port
```

如果检测到唯一设备，`make flash`、`make monitor`、`make run` 会直接使用它。

如果检测到多个设备，模板会停止自动选择，并提示你显式指定 `PORT`，例如：

```bash
make run PORT=/host-dev/serial/by-id/your-device
```

## 复用时的实践建议

- 新项目优先复制整个目录，而不是只拷一个 `main.c`
- 初期先保证 `make doctor` 和 `make flash-monitor` 通，再继续加业务功能
- 每次改完 `sdkconfig.defaults` 后，执行一次 `make reconfigure`
- 优先保留统一的 `Makefile` 工作流，避免每个项目命令风格都不一样

## 串口覆盖

如果你不想使用自动发现，也可以手动覆盖：

```text
PORT=/host-dev/serial/by-id/your-device
```

例如：

```bash
make flash PORT=/host-dev/serial/by-id/your-device
```


## 使用创建脚本后的建议

- 当前目标芯片：`esp32c3`
- 运行 `cd /workspaces/ESP32_dev/WirelessID` 进入工程目录
- 已自动生成 `.vscode/settings.json`、`launch.json`、`tasks.json`、`extensions.json`
- 创建脚本串口策略：`auto`
- 首次建议执行 `make build` 验证工程与调试配置是否正常
