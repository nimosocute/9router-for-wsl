#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="9router.service"

log() {
  printf '[9router-wsl] %s\n' "$*"
}

if command -v systemctl >/dev/null 2>&1 && systemctl --user status >/dev/null 2>&1; then
  systemctl --user stop "$SERVICE_NAME" >/dev/null 2>&1 || true
  systemctl --user disable "$SERVICE_NAME" >/dev/null 2>&1 || true
  systemctl --user daemon-reload >/dev/null 2>&1 || true
fi

rm -f "$HOME/.config/systemd/user/$SERVICE_NAME"
rm -f "$HOME/bin/open-9router-dashboard.sh"

if grep -qi microsoft /proc/sys/kernel/osrelease 2>/dev/null; then
  startup_win="$(powershell.exe -NoProfile -Command '[Environment]::GetFolderPath("Startup")' 2>/dev/null | tr -d '\r' || true)"
  if [ -n "$startup_win" ]; then
    startup_wsl="$(wslpath -u "$startup_win")"
    rm -f "$startup_wsl/Start WSL 9Router.vbs"
  fi
fi

log "removed systemd user service, dashboard opener, and Windows Startup entry"
log "9router npm package and user data were not removed"
