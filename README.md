# 9Router WSL Autostart

Run 9Router reliably in WSL with a user `systemd` service.

This installer:

- creates a `systemd --user` service with `Restart=always`
- opens the 9Router dashboard after the server is ready
- creates a Windows Startup entry that starts the WSL service on login
- leaves Codex/model configuration untouched

It does **not** edit `~/.codex/config.toml`, select models, add provider credentials, or configure 9Router routing. Users should do that themselves in the 9Router dashboard.

## Requirements

- Windows with WSL2
- A Linux distro with `systemd` enabled
- `bash`, `curl`, `systemctl`
- 9Router already installed in WSL

For WSL, `/etc/wsl.conf` should include:

```ini
[boot]
systemd=true
```

After changing that file, restart WSL from Windows:

```powershell
wsl --shutdown
```

Then open the distro again.

## Install

From inside WSL:

```bash
npm install -g 9router
```

Then run the autostart setup:

```bash
curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-wsl-autostart/main/install.sh | bash
```

The setup command creates the WSL `systemd` user service and, when possible, also creates the Windows Startup entry from WSL.

If you want a single copy-paste command after opening WSL:

```bash
npm install -g 9router && curl -fsSL https://raw.githubusercontent.com/nimosocute/9router-wsl-autostart/main/install.sh | bash
```

For local development only, you can clone and run:

```bash
git clone https://github.com/nimosocute/9router-wsl-autostart.git
cd 9router-wsl-autostart
bash install.sh
```

## Daily Use

After installation:

1. Log in to Windows.
2. The Windows Startup entry calls WSL.
3. WSL starts `9router.service`.
4. 9Router runs in the background and restarts if it exits.
5. The dashboard opens after the API is ready.

API endpoint:

```text
http://127.0.0.1:20128/v1
```

Dashboard:

```text
http://localhost:20128/dashboard
```

## Commands

Check status:

```bash
systemctl --user status 9router.service
```

Restart:

```bash
systemctl --user restart 9router.service
```

Stop:

```bash
systemctl --user stop 9router.service
```

Open dashboard manually:

```bash
~/bin/open-9router-dashboard.sh
```

Check API:

```bash
curl http://127.0.0.1:20128/v1/models
```

## Options

Set environment variables before running `install.sh`.

Use a different port:

```bash
9ROUTER_PORT=20129 bash install.sh
```

Bind to a different host:

```bash
9ROUTER_HOST=0.0.0.0 bash install.sh
```

Do not open the dashboard automatically:

```bash
OPEN_DASHBOARD=0 bash install.sh
```

Do not create a Windows Startup entry:

```bash
ENABLE_WINDOWS_STARTUP=0 bash install.sh
```

Use a custom npm global prefix:

```bash
NPM_CONFIG_PREFIX="$HOME/.npm-global" bash install.sh
```

## Uninstall

```bash
bash uninstall.sh
```

This removes:

- the `systemd --user` service
- the dashboard opener script
- the Windows Startup entry

It does not remove:

- the 9Router npm package
- 9Router user data
- provider credentials
- Codex config

## Notes

The installer intentionally avoids configuring models or credentials. If Codex, Claude Code, or another tool reports an error like "No active credentials for provider", open the 9Router dashboard and configure the provider/model routing there.
