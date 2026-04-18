# ESP32-C3 在当前 Docker / WSL / Dev Container 中的串口下载说明

本文档针对你当前这台机器的实际情况整理：

- Windows 宿主机使用 `usbipd-win 5.3.0`
- 通过 WSL 进入 Linux 环境
- 再通过 VS Code Dev Container 进入当前容器
- 目标芯片是 **ESP32-C3**

## 1. 你当前识别到的目标设备

从前面的 `usbipd list` 与你后续在容器内确认的结果来看，当前实际可用的串口设备为：

```text
/host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00
```

这说明：

- Windows / WSL / Dev Container 这条链路已经打通
- 当前可以直接使用稳定的 `by-id` 设备路径进行烧录与日志查看
- 相比 `/dev/ttyUSB0` 这类名字，`/host-dev/serial/by-id/...` 更不容易因为重插设备而变化

对于 ESP32-C3，这种写法更稳妥，建议后续优先使用该路径。

## 3. 正确的整体流程

### 第一步：在 Windows PowerShell 中附加 USB 设备到 WSL

建议执行：

```powershell
usbipd attach --wsl --busid 9-2 --auto-attach
```

如果你使用的是特定 WSL 发行版，也可以写成：

```powershell
usbipd attach --wsl <你的发行版名> --busid 9-2 --auto-attach
```

比如：

```powershell
usbipd attach --wsl Ubuntu --busid 9-2 --auto-attach
```

### 第二步：在 WSL 里确认串口是否出现

进入 WSL 后执行：

```bash
ls /dev/ttyUSB* /dev/ttyACM*
```

理想情况下，你会看到类似：

```bash
/dev/ttyUSB0
```

因为你的设备是 CH343，**大概率会是 `ttyUSB0`**，不是 `ttyACM0`。

## 4. 我已经帮你修改了当前 devcontainer

我已经把当前仓库的：

```text
.devcontainer/devcontainer.json
```

补上了设备透传配置：

```json
"runArgs": [
  "--device=/dev/ttyUSB0:/dev/ttyUSB0",
  "--device=/dev/ttyUSB1:/dev/ttyUSB1",
  "--device=/dev/ttyACM0:/dev/ttyACM0",
  "--device=/dev/ttyACM1:/dev/ttyACM1"
]
```

这一步的作用是：

- 先让 Windows 把 USB 设备交给 WSL
- 再让 Dev Container 把 WSL 里的串口设备带进容器

## 5. 你下一步必须做什么

改完 `devcontainer.json` 后，**必须重建容器**。

在 VS Code 里执行：

- `Dev Containers: Rebuild and Reopen in Container`

因为 `--device` 是容器启动参数，不重建不会生效。

## 6. 重建后怎么验证

### 6.1 在容器里检查串口

进入容器后执行：

```bash
ls /dev/ttyUSB* /dev/ttyACM*
```

如果你的 CH343 已经从 Windows 正确附加到 WSL，并且容器也重建了，那么大概率会看到：

```bash
/dev/ttyUSB0
```

### 6.2 进入模板工程

```bash
cd /workspaces/ESP32_dev/user_template
```

### 6.3 编译

```bash
idf.py build
```

### 6.4 烧录并打开日志

优先使用你已经确认好的稳定串口路径：

```bash
idf.py -p /host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00 flash monitor
```

如果后续设备路径发生变化，再回退检查：

- `/host-dev/serial/by-id/`
- `/dev/ttyUSB0`
- `/dev/ttyUSB1`
- `/dev/ttyACM0`

### 6.5 仅烧录命令

如果你只想烧录，不立即进入串口监视，执行：

```bash
idf.py -p /host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00 flash
```

### 6.6 仅打开串口日志

如果程序已经烧录完成，只想单独看串口输出，执行：

```bash
idf.py -p /host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00 monitor
```

退出串口监视常用组合键：

```text
Ctrl + ]
```

## 7. ESP32-C3 的注意事项

### 7.1 自动下载失败时

有些 ESP32-C3 板子自动下载不稳定，这时可以手动让芯片进入下载模式：

1. 按住 **BOOT**
2. 按一下 **EN / RESET**
3. 松开 **EN / RESET**
4. 再松开 **BOOT**
5. 然后重新执行：

```bash
idf.py -p /host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00 flash
```

### 7.2 你的当前设备更像传统 USB 转串口

因为你现在识别到的是：

```text
USB-Enhanced-SERIAL CH343
```

所以它更像标准 USB-UART 桥接芯片；底层通常仍会映射成 `/dev/ttyUSB0`，但在当前容器环境里，**优先使用已经确认稳定的 `/host-dev/serial/by-id/...` 路径进行操作**。

这和某些板载原生 USB 的 ESP32-C3 板子不一样。

## 8. 你现在应该执行的命令

### Windows PowerShell

```powershell
usbipd attach --wsl --busid 9-2 --auto-attach
```

### 重建 Dev Container 后，在容器里

```bash
ls /dev/ttyUSB* /dev/ttyACM*
cd /workspaces/ESP32_dev/user_template
idf.py build
idf.py -p /host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00 flash
idf.py -p /host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00 monitor
```

或者一步完成：

```bash
idf.py -p /host-dev/serial/by-id/usb-1a86_USB_Single_Serial_5C37267536-if00 flash monitor
```

## 9. 结果判断

如果一切正常，你在串口 monitor 里应该能看到：

```text
I (...) user_template: ESP32-C3 minimal app started
I (...) user_template: If you can see this log, build, flash, and monitor are working
```
