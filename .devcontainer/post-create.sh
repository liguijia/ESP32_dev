#!/usr/bin/env bash
set -euo pipefail

ZSHRC="$HOME/.zshrc"

if [ -f "$ZSHRC" ]; then
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="jonathan"/' "$ZSHRC"
else
  printf 'ZSH_THEME="jonathan"\n' > "$ZSHRC"
fi

grep -qxF 'export PATH="/usr/local/bin:$PATH"' "$ZSHRC" || printf 'export PATH="/usr/local/bin:$PATH"\n' >> "$ZSHRC"

if ! grep -qxF 'export IDF_PATH="/opt/esp/idf"' "$ZSHRC"; then
  printf 'export IDF_PATH="/opt/esp/idf"\n' >> "$ZSHRC"
fi

if ! grep -qxF '. "/opt/esp/idf/export.sh" >/dev/null 2>&1' "$ZSHRC"; then
  printf 'if [ -f "/opt/esp/idf/export.sh" ]; then\n  . "/opt/esp/idf/export.sh" >/dev/null 2>&1\nfi\n' >> "$ZSHRC"
fi

mkdir -p \
  "$HOME/.config" \
  "$HOME/.local/share/opencode" \
  "$HOME/.cache/opencode" \
  "$HOME/.local/state/opencode"

[ -d /host-home/.codex ] && ln -snf /host-home/.codex "$HOME/.codex" || true
[ -d /host-home/.claude ] && ln -snf /host-home/.claude "$HOME/.claude" || true
[ -d /host-home/.agents ] && ln -snf /host-home/.agents "$HOME/.agents" || true
# OpenCode: 选择性链接配置文件（跳过 node_modules，避免 Windows 原生二进制不兼容）
if [ -d /host-home/.config/opencode ]; then
  # 移除之前的 blanket symlink（如果是从旧版脚本创建的）
  if [ -L "$HOME/.config/opencode" ]; then
    rm -f "$HOME/.config/opencode"
  fi

  # 确保容器配置目录是真实目录
  mkdir -p "$HOME/.config/opencode"

  # 逐个 symlink 配置文件（写入会同步回 Windows 主机）
  for f in opencode.json oh-my-openagent.json; do
    if [ -f "/host-home/.config/opencode/$f" ]; then
      ln -snf "/host-home/.config/opencode/$f" "$HOME/.config/opencode/$f"
    fi
  done

  # symlink 配置目录（排除 node_modules，避免跨平台二进制不兼容）
  for dir in agents commands modes plugins skills tools themes; do
    if [ -d "/host-home/.config/opencode/$dir" ]; then
      [ -e "$HOME/.config/opencode/$dir" ] && rm -rf "$HOME/.config/opencode/$dir"
      ln -snf "/host-home/.config/opencode/$dir" "$HOME/.config/opencode/$dir"
    fi
  done

  # 移除不兼容的 Windows node_modules
  if [ -d "$HOME/.config/opencode/node_modules" ]; then
    rm -rf "$HOME/.config/opencode/node_modules"
    rm -f "$HOME/.config/opencode/package.json" "$HOME/.config/opencode/package-lock.json" 2>/dev/null || true
  fi

  # 为 Linux 容器重新安装插件
  if command -v opencode &>/dev/null; then
    echo "[post-create] Installing opencode plugin: oh-my-openagent@latest"
    if ! opencode plugin install oh-my-openagent@latest; then
      echo "[post-create] WARNING: opencode plugin install failed. Plugin-dependent features may not work." >&2
    fi
  else
    echo "[post-create] WARNING: opencode CLI not found in PATH. Plugins will not be installed." >&2
  fi
fi

if [ -f /host-home/.local/share/opencode/auth.json ] && [ ! -f "$HOME/.local/share/opencode/auth.json" ]; then
  cp /host-home/.local/share/opencode/auth.json "$HOME/.local/share/opencode/auth.json"
fi

if [ -f /host-home/.local/share/opencode/mcp-auth.json ] && [ ! -f "$HOME/.local/share/opencode/mcp-auth.json" ]; then
  cp /host-home/.local/share/opencode/mcp-auth.json "$HOME/.local/share/opencode/mcp-auth.json"
fi

cat > /usr/local/bin/esp32-port <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

for pattern in /host-dev/serial/by-id/* /host-dev/ttyACM* /host-dev/ttyUSB*; do
  for path in $pattern; do
    if [ -e "$path" ]; then
      printf '%s\n' "$path"
      exit 0
    fi
  done
done

exit 1
EOF

chmod +x /usr/local/bin/esp32-port
