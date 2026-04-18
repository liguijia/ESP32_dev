# ESP 开发与调试指南（当前 Docker 容器 / 工作区）

本文档基于当前工作区实际内容整理，适用于本仓库里的 ESP-IDF 开发环境。

## 1. 当前环境概览

从当前工作区可以确认：

- 工作区根目录：`/workspaces/ESP32_dev`
- 容器配置目录：`.devcontainer/`
- 当前已有示例工程：`hello_world/`
- 当前示例工程使用 **ESP-IDF**，不是 PlatformIO
- 容器基础镜像：`biggates/esp-idf-devcontainer:idf_v5.4.2_qemu_20250228`
- 当前 ESP-IDF 版本：**5.4.2**
- 当前示例目标芯片：**esp32c3**
- 默认串口监视波特率：**115200**

这些信息分别来自：

- `.devcontainer/devcontainer.json`
- `.devcontainer/Dockerfile`
- `hello_world/CMakeLists.txt`
- `hello_world/sdkconfig`
- `hello_world/build/project_description.json`

## 2. 当前工作区结构说明

当前工作区的核心目录如下：

```text
ESP32_dev/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── Dockerfile
│   └── post-create.sh
├── hello_world/
│   ├── CMakeLists.txt
│   ├── sdkconfig
│   ├── main/
│   │   ├── CMakeLists.txt
│   │   └── hello_world.c
│   └── build/
└── doc/
```

### 各部分用途

#### `.devcontainer/`

用于定义开发容器：

- `devcontainer.json`：告诉 VS Code 如何启动这个容器、挂载工作区、安装插件、执行初始化脚本
- `Dockerfile`：定义容器镜像，里面已经准备好了 ESP-IDF 环境、Node.js、zsh 等
- `post-create.sh`：容器创建后执行的初始化脚本，用于整理 shell 环境和一些本地配置映射

#### `hello_world/`

这是一个标准的 ESP-IDF 工程目录：

- `CMakeLists.txt`：项目入口，调用 ESP-IDF 的 CMake 系统
- `main/CMakeLists.txt`：注册当前组件源码
- `main/hello_world.c`：应用入口代码，`app_main()` 是主入口
- `sdkconfig`：项目配置文件
- `build/`：编译输出目录，里面已经有 `.bin`、`.elf`、`gdbinit`、flash 参数等产物

## 3. 如何使用当前容器进行开发

### 3.1 推荐使用方式

推荐方式是用 **VS Code + Dev Containers** 打开当前工作区。

原因是这个仓库已经为 Dev Container 配好了：

- ESP-IDF 基础镜像
- Espressif 官方 VS Code 插件：`espressif.esp-idf-extension`
- 容器内默认 shell：`zsh`
- post-create 初始化逻辑

### 3.2 打开步骤

1. 在宿主机安装：
   - Docker
   - VS Code
   - Dev Containers 扩展
2. 用 VS Code 打开 `ESP32_dev` 目录
3. 执行：`Reopen in Container`
4. 等待容器构建和初始化完成

### 3.3 容器里已经有哪些能力

从 `.devcontainer/Dockerfile` 可以看出，容器中已经准备了：

- ESP-IDF 完整工具链
- Python / CMake / Ninja（由 ESP-IDF 基础镜像提供）
- Node.js 20
- `@openai/codex`、`opencode-ai`
- `git`
- `zsh`

这意味着你进入容器后，通常不需要再手动安装 ESP-IDF。

## 4. 在当前工作区中如何开发 ESP 工程

### 4.1 进入工程目录

当前已有工程是：

```bash
cd /workspaces/ESP32_dev/hello_world
```

后续的 `idf.py` 命令建议都在这个目录下执行。

### 4.2 应用入口在哪里

当前应用入口文件：

```text
hello_world/main/hello_world.c
```

入口函数：

```c
void app_main(void)
{

}
```

你后续开发时，通常就是在这里开始写初始化逻辑，比如：

- GPIO
- UART
- Wi-Fi
- I2C / SPI
- FreeRTOS 任务
- 日志输出

### 4.3 新增源码时要注意

当前组件注册写在：

```text
hello_world/main/CMakeLists.txt
```

现在内容是：

```cmake
idf_component_register(SRCS "hello_world.c"
                    INCLUDE_DIRS ".")
```

如果你新增源文件，比如 `wifi_init.c`，要把它也加入 `SRCS`：

```cmake
idf_component_register(SRCS "hello_world.c" "wifi_init.c"
                    INCLUDE_DIRS ".")
```

## 5. 常用开发命令

下面这些命令是当前容器里进行 ESP-IDF 开发最常用的命令。

### 5.1 配置目标芯片

当前工程已经是 `esp32c3`，但如果你新建工程或者想重新设置目标，可以执行：

```bash
idf.py set-target esp32c3
```

当前工作区证据：`sdkconfig` 中存在：

```text
CONFIG_IDF_TARGET="esp32c3"
```

### 5.2 编译

```bash
idf.py build
```

编译完成后，产物通常在：

- `build/hello_world.bin`
- `build/hello_world.elf`
- `build/bootloader/`
- `build/partition_table/`

### 5.3 打开图形配置菜单

```bash
idf.py menuconfig
```

适合修改：

- 串口参数
- Flash 配置
- Wi-Fi / BLE 选项
- 日志等级
- FreeRTOS 配置

### 5.4 清理构建

```bash
idf.py clean
```

如果怀疑 CMake 缓存或目标切换导致问题，更稳妥的是：

```bash
idf.py fullclean
```

### 5.5 烧录

连接开发板后执行：

```bash
idf.py -p /dev/ttyUSB0 flash
```

如果是某些 ESP32-C3 板卡，也可能是：

- `/dev/ttyACM0`
- `/dev/ttyUSB1`

### 5.6 串口监视

```bash
idf.py -p /dev/ttyUSB0 monitor
```

当前项目默认监视波特率是：

```text
CONFIG_MONITOR_BAUD=115200
```

退出 monitor 常用快捷键：

- `Ctrl + ]`

### 5.7 一步完成编译、烧录、监视

开发阶段最常用：

```bash
idf.py -p /dev/ttyUSB0 flash monitor
```

这条命令很适合快速迭代。

## 6. 宿主机与容器的串口使用注意事项

这是 ESP 开发里最容易踩坑的部分。

### 6.1 容器必须能看到串口设备

如果你要在 Docker 容器里直接烧录芯片，容器必须能访问宿主机的串口设备，例如：

- `/dev/ttyUSB0`
- `/dev/ttyACM0`

如果容器看不到这些设备，就无法 `flash` 和 `monitor`。

### 6.2 你需要检查什么

在宿主机先确认设备名：

```bash
ls /dev/ttyUSB* /dev/ttyACM*
```

然后再确认 Dev Container / Docker 启动时，是否把对应设备映射进容器。

### 6.3 如果容器里无法访问串口

常见处理思路：

1. 确认 USB 线支持数据传输，不只是充电
2. 确认宿主机识别到了串口设备
3. 确认容器启动参数包含设备映射
4. 确认没有被其他串口工具占用
5. 必要时重插开发板

### 6.4 关于当前仓库的说明

当前 `.devcontainer/devcontainer.json` 里已经配置了工作区挂载、环境变量和用户目录映射，**但从现有内容看，没有直接写出串口设备映射配置**。

这意味着：

- 如果你只是编译代码，当前配置通常已经够用
- 如果你要在容器中直接烧录 / 监视串口，可能还需要补充设备映射或在启动容器时传入设备权限

如果后面你愿意，我可以继续帮你把 `.devcontainer/devcontainer.json` 补成可直接访问串口设备的版本。

## 7. 当前工作区里的调试方式

ESP 开发里的“调试”通常分成三层：

1. **日志调试**
2. **串口监视调试**
3. **GDB / JTAG 级调试**

### 7.1 日志调试（最常用）

最实用、成本最低的方式，就是在代码里加日志。

典型写法：

```c
#include "esp_log.h"

static const char *TAG = "app";

void app_main(void)
{
    ESP_LOGI(TAG, "application start");
}
```

然后用：

```bash
idf.py -p /dev/ttyUSB0 monitor
```

查看运行输出。

### 7.2 通过串口观察启动过程

串口日志可以帮助你定位：

- 芯片是否成功启动
- 是否反复重启
- 是否触发 panic
- 分区表是否正常
- 外设初始化是否卡住

这是嵌入式最核心的调试路径。

### 7.3 GDB 相关准备

当前 `build/` 目录里已经能看到：

- `build/gdbinit/gdbinit`
- `build/gdbinit/connect`
- `build/gdbinit/symbols`
- `build/hello_world.elf`

这说明当前工程在构建后，已经生成了用于 GDB 调试的基础文件。

但要真正进行断点级调试，通常还需要：

- OpenOCD
- JTAG 调试器
- 或者板卡支持的 USB/JTAG 调试链路

如果只是普通 USB 串口线，没有 JTAG 能力，那么通常还是以日志调试和 monitor 为主。

### 7.4 什么时候需要 JTAG / GDB

以下情况建议升级到 JTAG 级调试：

- 程序早期启动就崩溃
- 怀疑任务切换、栈损坏、内存踩踏
- 需要断点、单步、查看寄存器或调用栈

## 8. 一个推荐的日常开发流程

建议按下面节奏开发：

### 第一步：修改代码

编辑：

```text
hello_world/main/hello_world.c
```

### 第二步：编译

```bash
idf.py build
```

### 第三步：烧录并查看输出

```bash
idf.py -p /dev/ttyUSB0 flash monitor
```

### 第四步：根据日志继续迭代

如果日志不够，就：

- 增加 `ESP_LOGI / ESP_LOGW / ESP_LOGE`
- 提高组件日志等级
- 必要时调整 `menuconfig`

### 第五步：遇到异常时做更深一层检查

比如：

- `idf.py fullclean && idf.py build`
- 检查 `sdkconfig`
- 检查目标芯片是否设置正确
- 检查串口是否选对
- 检查供电和 USB 连接是否稳定

## 9. 结合当前工作区的几点建议

### 9.1 先把 `hello_world` 跑通

因为当前工作区已经有一个现成工程，并且 `build/` 目录已经存在，所以最合理的起点不是重新搭环境，而是先把这个工程跑通。

建议先验证：

```bash
cd /workspaces/ESP32_dev/hello_world
idf.py build
idf.py -p /dev/ttyUSB0 flash monitor
```

### 9.2 新项目可以直接仿照这个目录结构

如果后面你要建自己的工程，建议继续沿用这个结构：

- 项目根目录保留 `CMakeLists.txt`
- `main/` 放应用入口
- `sdkconfig` 管理工程配置
- `build/` 作为构建输出

### 9.3 不建议手改 `sdkconfig`

当前 `sdkconfig` 文件开头已经写明：

```text
Automatically generated file. DO NOT EDIT.
```

更推荐通过：

```bash
idf.py menuconfig
```

来调整配置。

## 10. 常见问题排查

### 编译失败

优先检查：

- 是否在工程根目录执行 `idf.py`
- 目标芯片是否正确
- 是否做过 `fullclean`
- 代码是否忘记更新 `main/CMakeLists.txt`

### 烧录失败

优先检查：

- 串口路径是否正确
- 容器是否拿到了 USB 设备
- 板子是否进入下载模式
- USB 数据线是否正常

### monitor 没输出

优先检查：

- 波特率是否正确，当前项目是 `115200`
- 串口是否选错
- 程序是否根本没有启动成功
- 板卡是否不断复位

### 修改代码后没生效

优先检查：

- 是否真的重新执行了 `build`
- 是否真的重新 `flash`
- 是否刷到了正确设备

## 11. 最小可执行命令清单

如果你只想记住最重要的几条命令，可以记下面这组：

```bash
cd /workspaces/ESP32_dev/hello_world
idf.py build
idf.py -p /dev/ttyUSB0 flash
idf.py -p /dev/ttyUSB0 monitor
idf.py -p /dev/ttyUSB0 flash monitor
idf.py menuconfig
idf.py fullclean
```

## 12. 总结

当前这个工作区已经具备了一个可用的 ESP-IDF 开发基础：

- 有 Dev Container 配置
- 有 ESP-IDF 5.4.2 环境
- 有 VS Code 插件支持
- 有 `hello_world` 示例工程
- 目标芯片已经明确是 `esp32c3`

所以你现在最合适的使用方式是：

1. 用 VS Code 进入 Dev Container
2. 进入 `hello_world/` 目录开发
3. 用 `idf.py build` 编译
4. 用 `idf.py -p <串口> flash monitor` 烧录和查看日志
5. 遇到问题优先看串口日志，再决定是否上 GDB / JTAG

如果你后续要，我可以继续帮你补两类内容：

1. 给这个仓库补一个“可直接访问串口设备”的 devcontainer 配置
2. 把 `hello_world` 改成一个真正可运行、带日志输出的 ESP32-C3 示例程序
