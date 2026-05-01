#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_DIR="$(cd -- "${SCRIPT_DIR}/.." && pwd)"
TEMPLATE_DIR="${WORKSPACE_DIR}/user_template"
IDF_PY_BIN="${IDF_PY:-idf.py}"

TARGET_CHIP="esp32c3"
AUTO_INIT=1
PORT_MODE="auto"
POSITIONAL_ARGS=()

usage() {
  cat <<'EOF'
用法:
  ./script/create_user_project.sh [--target <chip>] [--port <auto|path>] [--no-init] <project_name> [target_dir]

说明:
  基于 /workspaces/ESP32_dev/user_template 创建一个新的用户工程。
  默认目标芯片为 esp32c3，并自动生成 VS Code 调试配置。

参数:
  project_name  新工程名，只允许字母、数字、下划线，且不能以数字开头
  target_dir    可选，目标工程完整路径；默认创建到工作区根目录下的 <project_name>

选项:
  --target, -t  目标芯片，可选值：esp32、esp32s2、esp32s3、esp32c3、esp32c5、esp32c6、esp32c61、esp32h2、esp32p4
  --port, -p    调试串口设置。auto 表示创建时自动探测；也可直接传入完整串口路径
  --no-init     只创建工程，不自动执行 idf.py set-target / reconfigure
  --help, -h    显示帮助

示例:
  ./script/create_user_project.sh blink_demo
  ./script/create_user_project.sh --target esp32s3 s3_demo
  ./script/create_user_project.sh --port auto blink_demo
  ./script/create_user_project.sh --port /host-dev/serial/by-id/your-device blink_demo
  ./script/create_user_project.sh -t esp32c6 sensor_app /workspaces/ESP32_dev/projects/sensor_app
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    -t|--target)
      if [[ $# -lt 2 ]]; then
        printf '缺少 --target 参数值。\n' >&2
        exit 1
      fi
      TARGET_CHIP="$2"
      shift 2
      ;;
    -p|--port)
      if [[ $# -lt 2 ]]; then
        printf '缺少 --port 参数值。\n' >&2
        exit 1
      fi
      PORT_MODE="$2"
      shift 2
      ;;
    --no-init)
      AUTO_INIT=0
      shift
      ;;
    --)
      shift
      while [[ $# -gt 0 ]]; do
        POSITIONAL_ARGS+=("$1")
        shift
      done
      ;;
    -*)
      printf '未知选项: %s\n' "$1" >&2
      usage >&2
      exit 1
      ;;
    *)
      POSITIONAL_ARGS+=("$1")
      shift
      ;;
  esac
done

if [[ ${#POSITIONAL_ARGS[@]} -lt 1 || ${#POSITIONAL_ARGS[@]} -gt 2 ]]; then
  usage >&2
  exit 1
fi

PROJECT_NAME="${POSITIONAL_ARGS[0]}"
TARGET_DIR="${POSITIONAL_ARGS[1]:-${WORKSPACE_DIR}/${PROJECT_NAME}}"

if [[ ! -d "${TEMPLATE_DIR}" ]]; then
  printf '模板目录不存在: %s\n' "${TEMPLATE_DIR}" >&2
  exit 1
fi

if [[ ! "${PROJECT_NAME}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
  printf '非法工程名: %s\n' "${PROJECT_NAME}" >&2
  printf '要求: 只允许字母、数字、下划线，且不能以数字开头。\n' >&2
  exit 1
fi

if [[ -e "${TARGET_DIR}" ]]; then
  printf '目标路径已存在: %s\n' "${TARGET_DIR}" >&2
  exit 1
fi

case "${TARGET_CHIP}" in
  esp32|esp32s2|esp32s3|esp32c3|esp32c5|esp32c6|esp32c61|esp32h2|esp32p4)
    ;;
  *)
    printf '不支持的目标芯片: %s\n' "${TARGET_CHIP}" >&2
    printf '当前支持: esp32, esp32s2, esp32s3, esp32c3, esp32c5, esp32c6, esp32c61, esp32h2, esp32p4\n' >&2
    exit 1
    ;;
esac

if [[ "${PORT_MODE}" != "auto" && "${PORT_MODE}" != /* ]]; then
  printf '不支持的 --port 参数值: %s\n' "${PORT_MODE}" >&2
  printf '请使用 auto 或完整绝对路径，例如 /host-dev/serial/by-id/your-device\n' >&2
  exit 1
fi

python3 - "${TEMPLATE_DIR}" "${TARGET_DIR}" "${PROJECT_NAME}" "${TARGET_CHIP}" "${PORT_MODE}" <<'PY'
from __future__ import annotations

import json
import shutil
import sys
from pathlib import Path


template_dir = Path(sys.argv[1]).resolve()
target_dir = Path(sys.argv[2]).resolve()
project_name = sys.argv[3]
target_chip = sys.argv[4]
port_mode = sys.argv[5]

token_old = "user_template"
token_old_upper = "USER_TEMPLATE"
token_new = project_name
token_new_upper = project_name.upper()

target_meta = {
    "esp32": {
        "display": "ESP32",
        "compiler": "/opt/esp/tools/xtensa-esp-elf/esp-14.2.0_20241119/xtensa-esp-elf/bin/xtensa-esp-elf-gcc",
        "openocd": ["board/esp32-wrover-kit-3.3v.cfg"],
    },
    "esp32s2": {
        "display": "ESP32-S2",
        "compiler": "/opt/esp/tools/xtensa-esp-elf/esp-14.2.0_20241119/xtensa-esp-elf/bin/xtensa-esp-elf-gcc",
        "openocd": ["board/esp32s2-kaluga-1.cfg"],
    },
    "esp32s3": {
        "display": "ESP32-S3",
        "compiler": "/opt/esp/tools/xtensa-esp-elf/esp-14.2.0_20241119/xtensa-esp-elf/bin/xtensa-esp-elf-gcc",
        "openocd": ["board/esp32s3-builtin.cfg"],
    },
    "esp32c3": {
        "display": "ESP32-C3",
        "compiler": "/opt/esp/tools/riscv32-esp-elf/esp-14.2.0_20241119/riscv32-esp-elf/bin/riscv32-esp-elf-gcc",
        "openocd": ["board/esp32c3-builtin.cfg"],
    },
    "esp32c5": {
        "display": "ESP32-C5",
        "compiler": "/opt/esp/tools/riscv32-esp-elf/esp-14.2.0_20241119/riscv32-esp-elf/bin/riscv32-esp-elf-gcc",
        "openocd": ["board/esp32c5-builtin.cfg"],
    },
    "esp32c6": {
        "display": "ESP32-C6",
        "compiler": "/opt/esp/tools/riscv32-esp-elf/esp-14.2.0_20241119/riscv32-esp-elf/bin/riscv32-esp-elf-gcc",
        "openocd": ["board/esp32c6-builtin.cfg"],
    },
    "esp32c61": {
        "display": "ESP32-C61",
        "compiler": "/opt/esp/tools/riscv32-esp-elf/esp-14.2.0_20241119/riscv32-esp-elf/bin/riscv32-esp-elf-gcc",
        "openocd": ["board/esp32c61-builtin.cfg"],
    },
    "esp32h2": {
        "display": "ESP32-H2",
        "compiler": "/opt/esp/tools/riscv32-esp-elf/esp-14.2.0_20241119/riscv32-esp-elf/bin/riscv32-esp-elf-gcc",
        "openocd": ["board/esp32h2-builtin.cfg"],
    },
    "esp32p4": {
        "display": "ESP32-P4",
        "compiler": "/opt/esp/tools/riscv32-esp-elf/esp-14.2.0_20241119/riscv32-esp-elf/bin/riscv32-esp-elf-gcc",
        "openocd": ["board/esp32p4-builtin.cfg"],
    },
}

meta = target_meta[target_chip]

ignore = shutil.ignore_patterns(
    "build",
    ".DS_Store",
    "sdkconfig.old",
    "managed_components",
    "dependencies.lock",
)

shutil.copytree(template_dir, target_dir, ignore=ignore)

rename_candidates = [
    target_dir / "main" / "user_template.c",
    target_dir / "main" / "include" / "user_template_config.h",
]

for old_path in rename_candidates:
    if old_path.exists():
        old_path.rename(old_path.with_name(old_path.name.replace(token_old, token_new)))

text_suffixes = {
    ".c",
    ".h",
    ".txt",
    ".md",
    ".cmake",
    ".defaults",
    ".project",
    ".json",
    ".yml",
    ".yaml",
    ".py",
    ".sh",
    ".mk",
    "",
}

for path in sorted(target_dir.rglob("*")):
    if not path.is_file():
        continue

    if path.name == "sdkconfig":
        continue

    if path.suffix not in text_suffixes and path.name not in {"Makefile", "CMakeLists.txt", ".gitignore", "README.md"}:
        continue

    try:
        content = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        continue

    updated = content.replace(token_old_upper, token_new_upper).replace(token_old, token_new)

    if updated != content:
        path.write_text(updated, encoding="utf-8")


def update_makefile(path: Path, chip: str, display_name: str) -> None:
    content = path.read_text(encoding="utf-8")

    if "TARGET ?=" not in content:
        content = content.replace("PROJECT_DIR := $(CURDIR)\n", f"PROJECT_DIR := $(CURDIR)\nTARGET ?= {chip}\n", 1)

    import re
    content = re.sub(r"ESP32(?:-[A-Z0-9]+)?\s+[^']+ 常用命令:", f"{display_name} {project_name} 常用命令:", content, count=1)
    content = content.replace("ESP32-C3 user_template 常用命令:", f"{display_name} {project_name} 常用命令:")
    content = content.replace(".PHONY: help build reconfigure fullclean clean flash app-flash bootloader-flash partition-flash erase erase-flash erase-app monitor log flash-monitor run reboot size menuconfig set-target-c3 port check-port doctor", ".PHONY: help build reconfigure fullclean clean flash app-flash bootloader-flash partition-flash erase erase-flash erase-app monitor log flash-monitor run reboot size menuconfig set-target port check-port doctor")
    content = content.replace("make set-target-c3  - 显式设置芯片为 esp32c3", "make set-target     - 显式设置芯片为当前 TARGET")
    content = content.replace("set-target-c3:", "set-target:")
    content = content.replace("$(IDF_PY) set-target esp32c3", "$(IDF_PY) set-target $(TARGET)")
    content = content.replace("--chip esp32c3", "--chip $(TARGET)")
    content = content.replace("== ESP32-C3 doctor ==", "== ESP32 doctor ==")
    content = content.replace(
        "@printf 'PROJECT_DIR=%s\\n' \"$(PROJECT_DIR)\"\n",
        "@printf 'PROJECT_DIR=%s\\n' \"$(PROJECT_DIR)\"\n\t@printf 'TARGET=%s\\n' \"$(TARGET)\"\n",
        1,
    )
    content = content.replace("  make erase-app APP_OFFSET=0x10000", "  make erase-app TARGET=esp32c6 APP_OFFSET=0x10000")
    content = content.replace("  make run BAUD=921600 MONITOR_BAUD=115200", "  make run TARGET=$(TARGET) BAUD=921600 MONITOR_BAUD=115200")
    content = content.replace("  make flash PORT=/host-dev/serial/by-id/your-device", "  make flash TARGET=$(TARGET) PORT=/host-dev/serial/by-id/your-device")

    path.write_text(content, encoding="utf-8")


def update_readme(path: Path, chip: str, display_name: str) -> None:
    content = path.read_text(encoding="utf-8")
    content = content.replace("ESP32-C3 + ESP-IDF", f"{display_name} + ESP-IDF")
    content = content.replace("ESP32-C3 reusable template started", f"{display_name} reusable template started")
    content = content.replace("新建一个最小可运行的 ESP32-C3 应用", f"新建一个最小可运行的 {display_name} 应用")
    content = content.replace("## 使用创建脚本后的建议", "## 使用创建脚本后的建议")
    path.write_text(content, encoding="utf-8")


def create_vscode_dir(project_root: Path, chip: str, compiler_path: str, openocd_configs: list[str], port_mode: str) -> None:
    def detect_serial_port() -> str | None:
        patterns = [
            "/host-dev/serial/by-id/*",
            "/dev/serial/by-id/*",
            "/host-dev/ttyACM*",
            "/host-dev/ttyUSB*",
            "/dev/ttyACM*",
            "/dev/ttyUSB*",
        ]

        for pattern in patterns:
            matches = sorted(str(path) for path in Path("/").glob(pattern.lstrip("/")) if path.exists())
            deduped = list(dict.fromkeys(matches))
            if len(deduped) == 1:
                return deduped[0]
            if len(deduped) > 1:
                return None
        return None

    vscode_dir = project_root / ".vscode"
    vscode_dir.mkdir(parents=True, exist_ok=True)

    detected_port = detect_serial_port() if port_mode == "auto" else port_mode

    settings = {
        "idf.customExtraVars": {
            "IDF_TARGET": chip,
        },
        "idf.openOcdConfigs": openocd_configs,
        "idf.flashType": "UART",
        "C_Cpp.default.compileCommands": "${workspaceFolder}/build/compile_commands.json",
        "C_Cpp.default.configurationProvider": "espressif.esp-idf-extension",
        "C_Cpp.default.intelliSenseMode": "linux-gcc-x64",
        "C_Cpp.default.compilerPath": compiler_path,
        "clangd.arguments": [
            "--compile-commands-dir=${workspaceFolder}/build",
        ],
    }

    if detected_port is not None:
        settings["idf.port"] = detected_port

    launch = {
        "version": "0.2.0",
        "configurations": [
            {
                "type": "espidf",
                "name": "ESP-IDF Debug: Launch",
                "request": "launch",
            }
        ],
    }

    tasks = {
        "version": "2.0.0",
        "tasks": [
            {
                "label": "ESP-IDF: Build",
                "type": "shell",
                "command": "make build",
                "options": {"cwd": "${workspaceFolder}"},
                "group": {"kind": "build", "isDefault": True},
                "problemMatcher": [],
            },
            {
                "label": "ESP-IDF: Reconfigure",
                "type": "shell",
                "command": "make reconfigure",
                "options": {"cwd": "${workspaceFolder}"},
                "problemMatcher": [],
            },
            {
                "label": "ESP-IDF: Flash",
                "type": "shell",
                "command": "make flash",
                "options": {"cwd": "${workspaceFolder}"},
                "problemMatcher": [],
            },
            {
                "label": "ESP-IDF: Monitor",
                "type": "shell",
                "command": "make monitor",
                "options": {"cwd": "${workspaceFolder}"},
                "problemMatcher": [],
            },
            {
                "label": "ESP-IDF: Flash and Monitor",
                "type": "shell",
                "command": "make flash-monitor",
                "options": {"cwd": "${workspaceFolder}"},
                "problemMatcher": [],
            },
            {
                "label": "ESP-IDF: Doctor",
                "type": "shell",
                "command": "make doctor",
                "options": {"cwd": "${workspaceFolder}"},
                "problemMatcher": [],
            },
            {
                "label": "ESP-IDF: Port",
                "type": "shell",
                "command": "make port",
                "options": {"cwd": "${workspaceFolder}"},
                "problemMatcher": [],
            },
        ],
    }

    extensions = {
        "recommendations": [
            "espressif.esp-idf-extension",
            "llvm-vs-code-extensions.vscode-clangd",
            "ms-vscode.cpptools",
        ]
    }

    (vscode_dir / "settings.json").write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (vscode_dir / "launch.json").write_text(json.dumps(launch, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (vscode_dir / "tasks.json").write_text(json.dumps(tasks, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    (vscode_dir / "extensions.json").write_text(json.dumps(extensions, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


update_makefile(target_dir / "Makefile", target_chip, meta["display"])
update_readme(target_dir / "README.md", target_chip, meta["display"])
create_vscode_dir(target_dir, target_chip, meta["compiler"], meta["openocd"], port_mode)

readme_path = target_dir / "README.md"
if readme_path.exists():
    with readme_path.open("a", encoding="utf-8") as fp:
        fp.write("\n\n")
        fp.write("## 使用创建脚本后的建议\n\n")
        fp.write(f"- 当前目标芯片：`{target_chip}`\n")
        fp.write(f"- 运行 `cd {target_dir}` 进入工程目录\n")
        fp.write("- 已自动生成 `.vscode/settings.json`、`launch.json`、`tasks.json`、`extensions.json`\n")
        fp.write(f"- 创建脚本串口策略：`{port_mode}`\n")
        fp.write("- 首次建议执行 `make build` 验证工程与调试配置是否正常\n")

print(f"已创建工程: {target_dir}")
print(f"目标芯片: {target_chip}")
print(f"串口策略: {port_mode}")
print("已生成项目级 VS Code 调试配置。")
print("后续建议:")
print(f"  cd {target_dir}")
print("  make build")
print("  之后可直接使用 VS Code 的 ESP-IDF 调试配置")
PY

if [[ ${AUTO_INIT} -eq 1 ]]; then
  if command -v "${IDF_PY_BIN}" >/dev/null 2>&1; then
    printf '初始化工程目标芯片并生成基础构建配置...\n'
    if ! "${IDF_PY_BIN}" -C "${TARGET_DIR}" set-target "${TARGET_CHIP}"; then
      printf '警告: idf.py set-target 执行失败，请手动在工程目录执行。\n' >&2
    elif ! "${IDF_PY_BIN}" -C "${TARGET_DIR}" reconfigure; then
      printf '警告: idf.py reconfigure 执行失败，请手动在工程目录执行。\n' >&2
    else
      printf '已完成自动初始化：set-target + reconfigure\n'
    fi
  else
    printf '警告: 未找到 idf.py，已跳过自动初始化。\n' >&2
  fi
fi
