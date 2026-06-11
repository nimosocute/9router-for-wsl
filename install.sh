#!/usr/bin/env bash
set -euo pipefail

PORT="${9ROUTER_PORT:-20128}"
HOST="${9ROUTER_HOST:-127.0.0.1}"
NPM_PREFIX="${NPM_CONFIG_PREFIX:-$HOME/.npm-global}"
export PATH="$NPM_PREFIX/bin:$PATH"
INSTALL_9ROUTER="${INSTALL_9ROUTER:-auto}"
OPEN_DASHBOARD="${OPEN_DASHBOARD:-1}"
ENABLE_WINDOWS_STARTUP="${ENABLE_WINDOWS_STARTUP:-1}"
SERVICE_NAME="9router.service"

log() {
  printf '[9router-wsl] %s\n' "$*"
}

warn() {
  printf '[9router-wsl] warning: %s\n' "$*" >&2
}

die() {
  printf '[9router-wsl] error: %s\n' "$*" >&2
  exit 1
}

is_wsl() {
  grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

install_9router_if_needed() {
  if command -v 9router >/dev/null 2>&1; then
    log "9router found: $(command -v 9router)"
    return
  fi

  if [ "$INSTALL_9ROUTER" = "0" ] || [ "$INSTALL_9ROUTER" = "false" ]; then
    die "9router is not installed and INSTALL_9ROUTER=$INSTALL_9ROUTER"
  fi

  require_cmd npm
  log "9router not found; installing with npm prefix: $NPM_PREFIX"
  mkdir -p "$NPM_PREFIX"
  npm config set prefix "$NPM_PREFIX" >/dev/null
  npm install -g 9router
}

ensure_path_line() {
  local shell_rc="$1"
  local line="export PATH=\"$NPM_PREFIX/bin:\$PATH\""
  touch "$shell_rc"
  if ! grep -Fqx "$line" "$shell_rc"; then
    printf '\n%s\n' "$line" >> "$shell_rc"
    log "added npm global bin to $shell_rc"
  fi
}

write_dashboard_opener() {
  mkdir -p "$HOME/bin"
  cat > "$HOME/bin/open-9router-dashboard.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail

PORT="${9ROUTER_PORT:-20128}"
URL="http://localhost:${PORT}/dashboard"
READY="http://127.0.0.1:${PORT}/v1/models"

for _ in $(seq 1 30); do
  if curl -fsS "$READY" >/dev/null 2>&1; then
    if command -v wslview >/dev/null 2>&1; then
      wslview "$URL" >/dev/null 2>&1 || true
    elif command -v xdg-open >/dev/null 2>&1; then
      xdg-open "$URL" >/dev/null 2>&1 || true
    else
      printf '9Router dashboard: %s\n' "$URL"
    fi
    exit 0
  fi
  sleep 1
done

exit 0
EOF
  chmod +x "$HOME/bin/open-9router-dashboard.sh"
}

write_user_service() {
  mkdir -p "$HOME/.config/systemd/user"
  local router_bin
  router_bin="$(command -v 9router || true)"
  [ -n "$router_bin" ] || router_bin="$NPM_PREFIX/bin/9router"

  cat > "$HOME/.config/systemd/user/$SERVICE_NAME" <<EOF
[Unit]
Description=9Router background server for WSL
After=default.target network-online.target
Wants=network-online.target

[Service]
Type=simple
WorkingDirectory=%h
Environment=HOME=%h
Environment=PATH=%h/.npm-global/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
Environment=9ROUTER_PORT=$PORT

ExecStartPre=/usr/bin/bash -lc 'fuser -k $PORT/tcp 2>/dev/null || true; sleep 1'
ExecStart=$router_bin --host $HOST --port $PORT --tray --skip-update
EOF

  if [ "$OPEN_DASHBOARD" = "1" ] || [ "$OPEN_DASHBOARD" = "true" ]; then
    cat >> "$HOME/.config/systemd/user/$SERVICE_NAME" <<'EOF'
ExecStartPost=%h/bin/open-9router-dashboard.sh
EOF
  fi

  cat >> "$HOME/.config/systemd/user/$SERVICE_NAME" <<EOF
ExecStop=/usr/bin/bash -lc 'fuser -k $PORT/tcp 2>/dev/null || true'

Restart=always
RestartSec=5
KillMode=control-group
TimeoutStartSec=60
TimeoutStopSec=10

[Install]
WantedBy=default.target
EOF
}

enable_linger_best_effort() {
  if command -v loginctl >/dev/null 2>&1; then
    if loginctl show-user "$USER" 2>/dev/null | grep -q '^Linger=yes$'; then
      log "linger already enabled for $USER"
      return
    fi

    if loginctl enable-linger "$USER" >/dev/null 2>&1; then
      log "enabled linger for $USER"
    elif command -v sudo >/dev/null 2>&1 && sudo -n loginctl enable-linger "$USER" >/dev/null 2>&1; then
      log "enabled linger for $USER via sudo"
    else
      warn "could not enable linger automatically; service will still start when WSL user services start"
    fi
  fi
}

enable_systemd_service() {
  require_cmd systemctl
  systemctl --user daemon-reload
  systemctl --user enable "$SERVICE_NAME" >/dev/null
  systemctl --user restart "$SERVICE_NAME"
}

create_windows_startup_entry() {
  if [ "$ENABLE_WINDOWS_STARTUP" != "1" ] && [ "$ENABLE_WINDOWS_STARTUP" != "true" ]; then
    log "Windows Startup entry disabled by ENABLE_WINDOWS_STARTUP=$ENABLE_WINDOWS_STARTUP"
    return
  fi

  if ! is_wsl; then
    log "not running in WSL; skipping Windows Startup entry"
    return
  fi

  local distro="${WSL_DISTRO_NAME:-}"
  if [ -z "$distro" ]; then
    distro="$(powershell.exe -NoProfile -Command '(wsl.exe -l -q | Select-Object -First 1)' 2>/dev/null | tr -d '\r' || true)"
  fi
  [ -n "$distro" ] || {
    warn "could not detect WSL distro name; skipping Windows Startup entry"
    return
  }

  local startup_win startup_wsl vbs_path
  startup_win="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("Startup")' 2>/dev/null | tr -d '\r' || true)"
  [ -n "$startup_win" ] || {
    warn "could not find Windows Startup folder; skipping Windows Startup entry"
    return
  }

  startup_wsl="$(wslpath -u "$startup_win")"
  mkdir -p "$startup_wsl"
  vbs_path="$startup_wsl/Start WSL 9Router.vbs"

  cat > "$vbs_path" <<EOF
Set shell = CreateObject("WScript.Shell")
shell.Run "wsl.exe -d $distro --user $USER -- systemctl --user start $SERVICE_NAME", 0, False
EOF

  log "created Windows Startup entry: $startup_win\\Start WSL 9Router.vbs"
}

main() {
  require_cmd bash
  require_cmd curl

  if ! command -v systemctl >/dev/null 2>&1; then
    die "systemctl is required. In WSL, enable systemd in /etc/wsl.conf with [boot] systemd=true"
  fi

  if ! systemctl --user status >/dev/null 2>&1; then
    die "systemd user session is not available. Restart WSL after enabling systemd."
  fi

  install_9router_if_needed
  ensure_path_line "$HOME/.bashrc"
  write_dashboard_opener
  write_user_service
  enable_linger_best_effort
  enable_systemd_service
  create_windows_startup_entry

  log "done"
  log "service status: systemctl --user status $SERVICE_NAME"
  log "dashboard opener: $HOME/bin/open-9router-dashboard.sh"
  log "API endpoint: http://127.0.0.1:$PORT/v1"
  log "dashboard: http://localhost:$PORT/dashboard"
  log "Codex/model configuration is intentionally not changed."
}

main "$@"
