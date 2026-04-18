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
[ -d /host-home/.config/opencode ] && ln -snf /host-home/.config/opencode "$HOME/.config/opencode" || true

if [ -d /host-home/.cache/opencode ]; then
  cp -R /host-home/.cache/opencode/. "$HOME/.cache/opencode/" 2>/dev/null || true
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
